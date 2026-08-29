# frozen_string_literal: true

# FastMcp - Model Context Protocol for Rails.
# Mounts the MCP server on /mcp behind McpTokenTransport, which authenticates
# every request with a Doorkeeper access token. Equivalent to
# FastMcp.mount_in_rails(..., authenticate: true), except mount_in_rails cannot
# be given our own transport subclass.
require 'fast_mcp'
require Rails.root.join('lib/middleware/mcp_token_transport')

FastMcp.server = FastMcp::Server.new(
  name: Rails.application.class.module_parent_name.underscore.dasherize,
  version: '1.0.0',
  logger: Rails.logger
)

Rails.application.config.after_initialize do
  # Tools are discovered through ApplicationTool.descendants, which is only
  # populated once the classes are loaded — force it, since eager loading is off
  # in development and test. AuthenticatedTool is an abstract base, not a tool.
  Rails.autoloaders.main.eager_load_dir(Rails.root.join('app/tools'))
  FastMcp.server.register_tools(*ApplicationTool.descendants.reject { |klass| klass == AuthenticatedTool })
end

FastMcp.server.transport_klass = McpTokenTransport

# Inserted before Warden: Devise's failure app intercepts any 401 coming from a
# middleware below it and rewrites the WWW-Authenticate header, which would stop
# MCP clients from ever discovering the OAuth endpoints. Sitting above Warden
# also keeps MCP requests out of the session entirely — they carry a bearer token.
Rails.application.config.middleware.insert_before(
  Warden::Manager,
  McpTokenTransport,
  FastMcp.server,
  path_prefix: '/mcp',
  messages_route: 'messages',
  sse_route: 'sse',
  localhost_only: false,
  allowed_origins: FastMcp.default_rails_allowed_origins(Rails.application),
  logger: Rails.logger
)

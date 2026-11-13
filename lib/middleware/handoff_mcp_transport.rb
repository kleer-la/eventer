# frozen_string_literal: true

require Rails.root.join('lib/middleware/mcp_token_transport')

# The session-handoff connector's transport (#202): same streamable HTTP as the
# admin MCP, but a token is only good here if it carries the `handoff` scope and
# belongs to a HandoffUser, and a 401 points clients at this server's own
# protected-resource document.
class HandoffMcpTransport < McpTokenTransport
  private

  def valid_token?(token)
    OauthAccess.valid?(token, scope: 'handoff')
  end

  def resource_metadata_url(request)
    "#{request.base_url}/.well-known/oauth-protected-resource/handoff/mcp"
  end
end

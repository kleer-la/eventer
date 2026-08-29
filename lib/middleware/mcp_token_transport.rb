# frozen_string_literal: true

# MCP transport that authenticates every request with an OAuth 2.1 access token
# issued by Doorkeeper to an MCP client. Without a valid token it answers 401
# with a WWW-Authenticate header pointing at the protected-resource metadata,
# which is what makes the client start the OAuth flow.
#
# Not autoloadable (lib/middleware is excluded in config.autoload_lib): the
# initializer requires it directly, because middlewares are referenced at boot.
class McpTokenTransport < FastMcp::Transports::AuthenticatedRackTransport
  # Streamable HTTP (MCP 2025-03-26) on top of the SSE transport fast-mcp 1.6
  # ships: Claude Desktop / claude.ai connectors POST JSON-RPC straight to /mcp.
  # The server is stateless (JSON in, JSON out), so the same handler is reused;
  # GET (server-initiated stream) is not offered — 405, allowed by the spec —
  # and DELETE (end of session) answers 200.
  def handle_mcp_request(request, env)
    subpath = request.path[@path_prefix.length..].to_s
    return super if ['', '/'].exclude?(subpath)

    if auth_enabled? && !exempt_from_auth?(request.path)
      token = request.env["HTTP_#{@auth_header_name.upcase.tr('-', '_')}"]&.gsub('Bearer ', '')
      return unauthorized_response(request) unless valid_token?(token)
    end
    return [200, { 'Content-Type' => 'application/json' }, []] if request.delete?
    return method_not_allowed_response unless request.post?

    handle_streamable_post(request, get_server_for_request(request, env))
  end

  # fast-mcp writes responses through send_message (an SSE broadcast); over plain
  # HTTP they are captured per thread and returned as the body instead. No
  # response at all (a notification) means 202.
  def send_message(message)
    capture = Thread.current[:mcp_http_capture]
    return capture << (message.is_a?(String) ? message : JSON.generate(message)) if capture

    super
  end

  private

  def handle_streamable_post(request, server)
    Thread.current[:mcp_http_capture] = []
    body = request.body.read
    headers = request.env.select { |k, _v| k.start_with?('HTTP_') }
                         .transform_keys { |k| k.sub('HTTP_', '').downcase.tr('_', '-') }
    server.transport = self
    server.handle_request(body, headers: headers)
    responses = Thread.current[:mcp_http_capture]
    return [202, { 'Content-Type' => 'application/json' }, []] if responses.empty?

    [200, { 'Content-Type' => 'application/json' }, [responses.first]]
  rescue JSON::ParserError => e
    handle_parse_error(e)
  ensure
    Thread.current[:mcp_http_capture] = nil
  end

  # The base class turns authentication off entirely when auth_token is nil.
  # Here a credential is always required, so the server is never left open.
  def auth_enabled?
    true
  end

  def valid_token?(token)
    OauthAccess.valid?(token)
  end

  def unauthorized_response(request)
    status, headers, body = super
    metadata = "#{request.base_url}/.well-known/oauth-protected-resource"
    [status, headers.merge('WWW-Authenticate' => %(Bearer resource_metadata="#{metadata}")), body]
  end
end

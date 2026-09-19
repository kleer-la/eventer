# frozen_string_literal: true

# OAuth 2.1 for MCP clients: Claude Desktop / claude.ai / Claude Code register
# themselves (see Oauth::RegistrationsController), send the user through the
# regular Devise login plus a consent screen, and get tokens that
# McpTokenTransport and ApplicationTool accept. Public clients: authorization
# code + mandatory PKCE, no secret.
Doorkeeper.configure do
  orm :active_record

  # The user logged into the admin (Devise); if there is none, send them to the
  # login form and come back to the authorization request afterwards.
  # Two kinds of resource owner, told apart by the scope the client asks for:
  # `mcp` (the admin MCP) is authorized by a User, `handoff` (the session-handoff
  # connector, #202) by a HandoffUser signed in with Google. A request mixing
  # them is refused outright: one token, one kind of owner.
  resource_owner_authenticator do
    scopes = Doorkeeper::OAuth::Scopes.from_string(params[:scope].to_s)
    if scopes.exists?('handoff')
      if scopes.count > 1
        head :forbidden
      else
        current_handoff_user || begin
          session['handoff_return_to'] = request.fullpath
          redirect_to(handoff_sign_in_path)
        end
      end
    else
      current_user || begin
        session['user_return_to'] = request.fullpath
        redirect_to(new_user_session_path)
      end
    end
  end

  # Tokens record which model their owner is; without this a HandoffUser and a
  # User with the same id would be one and the same to the MCP servers.
  use_polymorphic_resource_owner

  admin_authenticator do
    current_user&.role?(:administrator) ? current_user : redirect_to(new_user_session_path)
  end

  grant_flows %w[authorization_code refresh_token]
  force_pkce
  # Claude's connectors come back to https://claude.ai/... ; Claude Code and the
  # MCP Inspector to http://localhost.
  force_ssl_in_redirect_uri { |uri| %w[localhost 127.0.0.1].exclude?(uri.host) }
  allow_token_introspection false

  access_token_expires_in 2.hours
  use_refresh_token
  revoke_previous_authorization_code_token
  hash_token_secrets
  hash_application_secrets

  default_scopes :mcp
  optional_scopes :handoff
  enforce_configured_scopes

  skip_authorization { false }
end

# Doorkeeper's consent screen has no layout of its own; reuse the Devise one so
# it looks like the rest of the admin login flow.
Rails.application.config.to_prepare do
  Doorkeeper::AuthorizationsController.layout 'devise'
end

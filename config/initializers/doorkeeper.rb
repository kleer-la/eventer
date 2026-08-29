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
  resource_owner_authenticator do
    current_user || begin
      session['user_return_to'] = request.fullpath
      redirect_to(new_user_session_path)
    end
  end

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
  optional_scopes []
  enforce_configured_scopes

  skip_authorization { false }
end

# Doorkeeper's consent screen has no layout of its own; reuse the Devise one so
# it looks like the rest of the admin login flow.
Rails.application.config.to_prepare do
  Doorkeeper::AuthorizationsController.layout 'devise'
end

# frozen_string_literal: true

module Oauth
  # Discovery documents required by the MCP authorization spec: RFC 8414
  # (authorization server) and RFC 9728 (protected resource), so a client can
  # find out where to authorize.
  class MetadataController < ActionController::API
    def authorization_server
      render json: {
        issuer: base_url,
        authorization_endpoint: "#{base_url}/oauth/authorize",
        token_endpoint: "#{base_url}/oauth/token",
        registration_endpoint: "#{base_url}/oauth/register",
        revocation_endpoint: "#{base_url}/oauth/revoke",
        response_types_supported: ['code'],
        response_modes_supported: ['query'],
        grant_types_supported: %w[authorization_code refresh_token],
        code_challenge_methods_supported: ['S256'],
        token_endpoint_auth_methods_supported: ['none'],
        revocation_endpoint_auth_methods_supported: ['none'],
        scopes_supported: ['mcp']
      }
    end

    def protected_resource
      render json: {
        resource: "#{base_url}/mcp",
        authorization_servers: [base_url],
        bearer_methods_supported: ['header'],
        scopes_supported: ['mcp']
      }
    end

    private

    def base_url = request.base_url
  end
end

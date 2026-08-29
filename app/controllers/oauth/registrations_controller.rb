# frozen_string_literal: true

module Oauth
  # Dynamic Client Registration (RFC 7591): Claude Desktop / claude.ai / Claude
  # Code register themselves as public clients (PKCE, no secret).
  class RegistrationsController < ActionController::API
    rate_limit to: 20, within: 10.minutes,
               with: -> { render json: { error: 'rate_limited' }, status: :too_many_requests }

    def create
      redirect_uris = Array(params[:redirect_uris]).map(&:to_s).compact_blank
      if redirect_uris.empty?
        return render json: { error: 'invalid_redirect_uri', error_description: 'redirect_uris is required' },
                      status: :bad_request
      end

      application = Doorkeeper::Application.new(name: params[:client_name].presence || 'MCP client',
                                                redirect_uri: redirect_uris.join("\n"),
                                                scopes: 'mcp', confidential: false)
      unless application.save
        return render json: { error: 'invalid_client_metadata',
                              error_description: application.errors.full_messages.join(', ') },
                      status: :bad_request
      end

      render json: {
        client_id: application.uid,
        client_id_issued_at: Integer(application.created_at.strftime('%s'), 10),
        client_name: application.name,
        redirect_uris: redirect_uris,
        token_endpoint_auth_method: 'none',
        grant_types: %w[authorization_code refresh_token],
        response_types: ['code'],
        scope: 'mcp'
      }, status: :created
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

# claude.ai keeps one connector per user but runs many workers and sessions, so
# a refresh can race with a request still carrying the old token, or with a
# second refresh of the same refresh token. Doorkeeper revokes on use (the
# previous_refresh_token column turns that on), so both races already work. What
# was missing (#242): the old token was never revoked, because the MCP checks
# tokens without Doorkeeper's authenticate; tokens expired every 2 hours; and a
# 401 for an expired token did not say so, so claude.ai started a new login
# instead of refreshing.
RSpec.describe 'refreshing an MCP OAuth token', type: :request do
  include Devise::Test::IntegrationHelpers
  include ActiveSupport::Testing::TimeHelpers

  let(:administrator) { create(:administrator) }
  let(:verifier) { SecureRandom.urlsafe_base64(48) }
  let(:challenge) { Base64.urlsafe_encode64(OpenSSL::Digest::SHA256.digest(verifier), padding: false) }
  let(:redirect_uri) { 'https://claude.ai/api/mcp/auth_callback' }

  # Registration, login and authorization code, as claude.ai does it.
  def first_token
    client_id = register_client
    post '/oauth/token', params: { grant_type: 'authorization_code', code: authorization_code(client_id),
                                   redirect_uri: redirect_uri, client_id: client_id, code_verifier: verifier }
    response.parsed_body.merge('client_id' => client_id)
  end

  def register_client
    post '/oauth/register', params: { client_name: 'Claude', redirect_uris: [redirect_uri] }, as: :json
    response.parsed_body['client_id']
  end

  def authorization_code(client_id)
    sign_in administrator
    post '/oauth/authorize', params: { client_id: client_id, redirect_uri: redirect_uri, response_type: 'code',
                                       scope: 'mcp', code_challenge: challenge, code_challenge_method: 'S256' }
    sign_out administrator
    Rack::Utils.parse_query(URI(response.headers['Location']).query)['code']
  end

  def refresh(token)
    post '/oauth/token', params: { grant_type: 'refresh_token', refresh_token: token['refresh_token'],
                                   client_id: token['client_id'] }
    [response.status, response.parsed_body]
  end

  def mcp_status(access_token)
    headers = { 'CONTENT_TYPE' => 'application/json' }
    headers['Authorization'] = "Bearer #{access_token}" if access_token
    post '/mcp', params: { jsonrpc: '2.0', method: 'tools/list', id: 1 }.to_json, headers: headers
    response.status
  end

  it 'lets two refreshes of the same refresh token both succeed' do
    token = first_token

    first_status, first = refresh(token)
    second_status, second = refresh(token)

    expect([first_status, second_status]).to eq [200, 200]
    expect(first['access_token']).not_to eq second['access_token']
    expect(mcp_status(second['access_token'])).to eq 200
  end

  it 'keeps the old access token working until the new one is used' do
    token = first_token
    _, fresh = refresh(token)

    expect(mcp_status(token['access_token'])).to eq 200

    expect(mcp_status(fresh['access_token'])).to eq 200
    expect(mcp_status(token['access_token'])).to eq 401
  end

  it 'issues access tokens that last a day' do
    expect(first_token['expires_in']).to eq 1.day.to_i
  end

  # RFC 6750 §3.1: a client told the token is invalid refreshes it; a bare 401
  # reads as "log in", which is what claude.ai did.
  it 'tells a client whose token expired to refresh it, and one without a token to log in' do
    token = first_token
    travel 1.day + 1.minute do
      expect(mcp_status(token['access_token'])).to eq 401
      expect(response.headers['WWW-Authenticate']).to include('error="invalid_token"', 'resource_metadata=')
    end

    expect(mcp_status(nil)).to eq 401
    expect(response.headers['WWW-Authenticate']).not_to include('error=')
  end
end

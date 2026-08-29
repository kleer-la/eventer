# frozen_string_literal: true

require 'rails_helper'

# OAuth 2.1 for MCP clients: metadata -> dynamic registration -> authorization
# (behind the Devise login) -> token with PKCE -> use against the MCP server
RSpec.describe 'OAuth for MCP clients', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:administrator) { create(:administrator) }
  let(:verifier) { SecureRandom.urlsafe_base64(48) }
  let(:challenge) { Base64.urlsafe_encode64(OpenSSL::Digest::SHA256.digest(verifier), padding: false) }
  let(:redirect_uri) { 'https://claude.ai/api/mcp/auth_callback' }

  def register_client(name: 'Claude Desktop', uris: [redirect_uri])
    post '/oauth/register', params: { client_name: name, redirect_uris: uris }, as: :json
    response.parsed_body
  end

  it 'publishes both discovery documents and answers 401 with WWW-Authenticate' do
    get '/.well-known/oauth-authorization-server'
    expect(response.parsed_body).to include(
      'authorization_endpoint' => 'http://www.example.com/oauth/authorize',
      'registration_endpoint' => 'http://www.example.com/oauth/register',
      'code_challenge_methods_supported' => ['S256'],
      'token_endpoint_auth_methods_supported' => ['none']
    )

    get '/.well-known/oauth-protected-resource'
    expect(response.parsed_body).to include('resource' => 'http://www.example.com/mcp',
                                            'authorization_servers' => ['http://www.example.com'])

    post '/mcp', params: { jsonrpc: '2.0', method: 'tools/list', id: 1 }.to_json,
                 headers: { 'CONTENT_TYPE' => 'application/json' }
    expect(response).to have_http_status(:unauthorized)
    expect(response.headers['WWW-Authenticate'])
      .to include('resource_metadata="http://www.example.com/.well-known/oauth-protected-resource"')
  end

  it 'registers a client, authorizes with PKCE and issues a token that identifies the user' do
    client = register_client
    expect(response).to have_http_status(:created)
    expect(client).to include('token_endpoint_auth_method' => 'none')

    authorize_params = { client_id: client['client_id'], redirect_uri: redirect_uri, response_type: 'code',
                         scope: 'mcp', state: 'xyz', code_challenge: challenge, code_challenge_method: 'S256' }

    get '/oauth/authorize', params: authorize_params
    expect(response).to redirect_to(new_user_session_path)

    sign_in administrator
    get '/oauth/authorize', params: authorize_params
    expect(response).to be_successful
    expect(response.body).to include('Claude Desktop')

    post '/oauth/authorize', params: authorize_params
    location = response.headers['Location']
    expect(location).to start_with("#{redirect_uri}?")
    query = Rack::Utils.parse_query(URI(location).query)
    expect(query['state']).to eq('xyz')

    post '/oauth/token', params: { grant_type: 'authorization_code', code: query['code'],
                                   redirect_uri: redirect_uri, client_id: client['client_id'],
                                   code_verifier: verifier }
    token = response.parsed_body
    expect(token).to include('token_type' => 'Bearer', 'scope' => 'mcp')
    expect(token['refresh_token']).to be_present

    access_token = token['access_token']
    expect(ListArticlesTool.new(headers: { 'authorization' => "Bearer #{access_token}" }).current_user)
      .to eq(administrator)
    expect(OauthAccess.valid?(access_token)).to be(true)

    Doorkeeper::AccessToken.by_token(access_token).revoke
    expect(OauthAccess.valid?(access_token)).to be(false)
    expect(ListArticlesTool.new(headers: { 'authorization' => "Bearer #{access_token}" }).current_user).to be_nil
  end

  it 'requires PKCE and only allows http redirect uris on localhost' do
    client = register_client
    sign_in administrator
    get '/oauth/authorize', params: { client_id: client['client_id'], redirect_uri: redirect_uri,
                                      response_type: 'code', scope: 'mcp' }
    expect(response.body).to include('Code challenge is required')

    register_client(name: 'Claude Code', uris: ['http://localhost:12345/callback'])
    expect(response).to have_http_status(:created)

    register_client(name: 'evil', uris: ['http://evil.example.com/cb'])
    expect(response).to have_http_status(:bad_request)

    register_client(uris: [])
    expect(response).to have_http_status(:bad_request)
  end
end

# frozen_string_literal: true

require 'rails_helper'

# The session-handoff MCP connector (#202): its own server on /handoff/mcp with
# one tool, its own OAuth scope, and no way across to the admin MCP.
RSpec.describe 'Handoff MCP connector', type: :request do
  include Devise::Test::IntegrationHelpers
  include ActiveSupport::Testing::TimeHelpers

  let(:handoff_user) { create(:handoff_user) }
  let(:administrator) { create(:administrator) }
  let(:redirect_uri) { 'https://claude.ai/api/mcp/auth_callback' }
  let(:verifier) { SecureRandom.urlsafe_base64(48) }
  let(:challenge) { Base64.urlsafe_encode64(OpenSSL::Digest::SHA256.digest(verifier), padding: false) }
  let(:application) do
    Doorkeeper::Application.create!(name: 'Claude', redirect_uri: redirect_uri, scopes: 'mcp handoff',
                                    confidential: false)
  end

  def issue_token(owner, scope)
    Doorkeeper::AccessToken.create!(application: application, resource_owner: owner, scopes: scope,
                                    expires_in: 2.hours, use_refresh_token: true).plaintext_token
  end

  def rpc(path, token, method, params = {})
    post path, params: { jsonrpc: '2.0', method: method, id: 1, params: params }.to_json,
               headers: { 'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'application/json',
                          'HTTP_AUTHORIZATION' => "Bearer #{token}" }
  end

  def call_tool(token, name, arguments)
    rpc('/handoff/mcp', token, 'tools/call', { name: name, arguments: arguments })
    JSON.parse(response.parsed_body.dig('result', 'content', 0, 'text'))
  end

  describe 'discovery' do
    it 'publishes protected-resource metadata of its own and points 401s at it' do
      get '/.well-known/oauth-protected-resource/handoff/mcp'
      expect(response.parsed_body).to include('resource' => 'http://www.example.com/handoff/mcp',
                                              'authorization_servers' => ['http://www.example.com'],
                                              'scopes_supported' => ['handoff'])

      get '/.well-known/oauth-authorization-server'
      expect(response.parsed_body['scopes_supported']).to include('mcp', 'handoff')

      post '/handoff/mcp', params: { jsonrpc: '2.0', method: 'tools/list', id: 1 }.to_json,
                           headers: { 'CONTENT_TYPE' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
      expect(response.headers['WWW-Authenticate'])
        .to include('resource_metadata="http://www.example.com/.well-known/oauth-protected-resource/handoff/mcp"')
    end
  end

  describe 'authorization' do
    let(:authorize_params) do
      { client_id: application.uid, redirect_uri: redirect_uri, response_type: 'code', scope: 'handoff',
        state: 'xyz', code_challenge: challenge, code_challenge_method: 'S256' }
    end

    it 'sends a stranger to the Google sign-in, then issues a token owned by the HandoffUser' do
      get '/oauth/authorize', params: authorize_params
      expect(response).to redirect_to(handoff_sign_in_path)

      sign_in handoff_user, scope: :handoff_user
      get '/oauth/authorize', params: authorize_params
      expect(response).to be_successful

      post '/oauth/authorize', params: authorize_params
      query = Rack::Utils.parse_query(URI(response.headers['Location']).query)
      post '/oauth/token', params: { grant_type: 'authorization_code', code: query['code'], redirect_uri: redirect_uri,
                                     client_id: application.uid, code_verifier: verifier }
      token = response.parsed_body
      expect(token).to include('scope' => 'handoff')
      expect(Doorkeeper::AccessToken.by_token(token['access_token']).resource_owner).to eq handoff_user
    end

    it 'shows a Spanish consent page naming the account, with a way to change it' do
      sign_in handoff_user, scope: :handoff_user
      get '/oauth/authorize', params: authorize_params

      expect(response.body).to include(handoff_user.email, 'Cambiar de cuenta', 'Autorizar', 'Denegar', 'Claude')
      expect(response.body).not_to include('translation missing')
    end

    it 'keeps the admin consent page as it was, with its scope translated' do
      sign_in administrator
      get '/oauth/authorize', params: authorize_params.merge(scope: 'mcp')

      expect(response.body).to include('Authorize', 'Deny')
      expect(response.body).not_to include('translation missing', 'Cambiar de cuenta')
    end

    it 'lets the person change account: sign out, Google again, back to the same authorization' do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: 'google_oauth2', uid: 'other-uid', info: { email: 'otra@example.com', name: 'Otra' },
        extra: { raw_info: { email_verified: true } }
      )
      sign_in handoff_user, scope: :handoff_user
      authorize_url = "/oauth/authorize?#{authorize_params.to_query}"

      delete handoff_sign_out_path(return_to: authorize_url)
      expect(response).to redirect_to(handoff_sign_in_path)

      post '/handoff/auth/google_oauth2'
      follow_redirect!
      expect(response).to redirect_to(authorize_url)
      expect(HandoffUser.find_by(email: 'otra@example.com')).to be_present
    ensure
      OmniAuth.config.mock_auth[:google_oauth2] = nil
    end

    it 'ignores a return_to that is not an authorization' do
      sign_in handoff_user, scope: :handoff_user

      delete handoff_sign_out_path(return_to: 'https://evil.example/x')
      expect(session['handoff_return_to']).to be_nil
    end

    it 'does not let an admin session authorize the handoff scope' do
      sign_in administrator
      get '/oauth/authorize', params: authorize_params

      expect(response).to redirect_to(handoff_sign_in_path)
    end

    it 'refuses a request mixing the two scopes' do
      sign_in handoff_user, scope: :handoff_user
      get '/oauth/authorize', params: authorize_params.merge(scope: 'handoff mcp')

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'isolation between the two servers' do
    it 'accepts a handoff token on /handoff/mcp only, and an mcp token on /mcp only' do
      handoff_token = issue_token(handoff_user, 'handoff')
      admin_token = issue_token(administrator, 'mcp')

      rpc('/handoff/mcp', handoff_token, 'tools/list')
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig('result', 'tools').map { |t| t['name'] }).to eq ['briefing_audio']

      rpc('/mcp', handoff_token, 'tools/list')
      expect(response).to have_http_status(:unauthorized)

      rpc('/handoff/mcp', admin_token, 'tools/list')
      expect(response).to have_http_status(:unauthorized)

      rpc('/mcp', admin_token, 'tools/list')
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig('result', 'tools').map { |t| t['name'] }).not_to include('briefing_audio')
    end

    it 'never resolves a HandoffUser as the admin User with the same id' do
      expect(handoff_user.id).to eq administrator.id
      token = issue_token(handoff_user, 'handoff')

      expect(OauthAccess.authenticate(token)).to be_nil
      expect(OauthAccess.handoff_user(token)).to eq handoff_user
    end
  end

  describe 'briefing_audio' do
    let(:token) { issue_token(handoff_user, 'handoff') }
    let(:beats) { [{ narration: 'Hola equipo', duration: 5 }, { narration: 'Chau' }] }

    before { allow(TtsBriefingService).to receive(:call).and_return('ID3 fake mp3 bytes') }

    it 'synthesizes, records the usage for the user and answers a download link that serves the mp3' do
      result = call_tool(token, 'briefing_audio', { beats: beats })

      expect(result['download_url']).to start_with('http://www.example.com/handoff/briefings/')
      expect(result['expires_at']).to be_present
      expect(TtsBriefingService).to have_received(:call).with(beats: [{ 'narration' => 'Hola equipo', 'duration' => 5 },
                                                                      { 'narration' => 'Chau' }],
                                                              voice: nil, rate: nil)
      expect(TtsUsage.last).to have_attributes(status: 'ok', owner_id: handoff_user.id, beats_count: 2)

      get result['download_url']
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq 'audio/mpeg'
      expect(response.body).to eq 'ID3 fake mp3 bytes'
    end

    it 'stops serving the link once it expires, and purges the audio' do
      result = call_tool(token, 'briefing_audio', { beats: beats })

      travel HandoffBriefing::TTL + 1.minute do
        get result['download_url']
        expect(response).to have_http_status(:not_found)

        call_tool(token, 'briefing_audio', { beats: beats })
        expect(HandoffBriefing.count).to eq 1
      end
    end

    it 'answers the quota as an error the assistant can relay' do
      Setting.create!(key: 'TTS_MAX_BRIEFINGS_PER_MONTH_PER_USER', value: '1')
      TtsUsage.create!(status: 'ok', beats_count: 1, chars: 1, owner_id: handoff_user.id)

      result = call_tool(token, 'briefing_audio', { beats: beats })

      expect(result['status']).to eq 'error'
      expect(result['errors'].first).to match(/quota/i)
      expect(TtsBriefingService).not_to have_received(:call)
    end

    it 'answers a bad briefing as an error' do
      allow(TtsBriefingService).to receive(:call).and_raise(TtsBriefingService::Error, 'no beat has narration')

      result = call_tool(token, 'briefing_audio', { beats: [{ narration: 'Hola' }] })

      expect(result['status']).to eq 'error'
      expect(result['errors'].first).to include('no beat has narration')
      expect(TtsUsage.last.status).to eq 'error'
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

# OmniAuth builds the Google redirect_uri from the request's host, and Rails
# takes that from Host or X-Forwarded-Host. A forged one would send Google a
# callback on someone else's host (CVE-2026-63183), so in production only our
# own hosts may start or finish a Google login.
RSpec.describe 'OmniAuth allowed hosts', type: :request do
  around do |example|
    test_mode = OmniAuth.config.test_mode
    allowed = OmniAuth.config.allowed_hosts
    OmniAuth.config.test_mode = false
    OmniAuth.config.allowed_hosts = OMNIAUTH_ALLOWED_HOSTS
    example.run
  ensure
    OmniAuth.config.test_mode = test_mode
    OmniAuth.config.allowed_hosts = allowed
  end

  it 'sends Google a callback on our own host' do
    post '/handoff/auth/google_oauth2', headers: { 'HOST' => 'handoff.kleer.la' }

    expect(response.location).to start_with('https://accounts.google.com/')
    redirect_uri = Rack::Utils.parse_query(URI(response.location).query)['redirect_uri']
    expect(redirect_uri).to eq 'http://handoff.kleer.la/handoff/auth/google_oauth2/callback'
  end

  it 'refuses a forged X-Forwarded-Host' do
    post '/handoff/auth/google_oauth2',
         headers: { 'HOST' => 'handoff.kleer.la', 'X-Forwarded-Host' => 'evil.example' }

    expect(response.location).not_to include('accounts.google.com')
    expect(response.location).to end_with('/handoff/sign_in')
  end

  it 'allows every host kamal-proxy routes to the app' do
    proxied = %w[config/deploy.yml config/deploy.qa.yml].flat_map do |file|
      YAML.load_file(Rails.root.join(file)).dig('proxy', 'hosts')
    end

    expect(OMNIAUTH_ALLOWED_HOSTS).to match_array(proxied)
  end
end

# frozen_string_literal: true

require 'rails_helper'

# refresh_website_cache: the one MCP tool that acts on the public site instead
# of on the database. Whoever edits content from a chat can make it visible
# without opening the admin.
RSpec.describe 'MCP website cache', type: :request do
  let(:user) { create(:administrator) }
  let(:oauth_application) do
    Doorkeeper::Application.create!(name: 'Claude', redirect_uri: 'https://claude.ai/api/mcp/auth_callback',
                                    scopes: 'mcp', confidential: false)
  end
  let(:access_token) do
    Doorkeeper::AccessToken.create!(application: oauth_application, resource_owner_id: user.id,
                                    scopes: 'mcp', expires_in: 2.hours, use_refresh_token: true).plaintext_token
  end
  let(:headers) do
    { 'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'application/json, text/event-stream',
      'HTTP_AUTHORIZATION' => "Bearer #{access_token}" }
  end
  let(:endpoint) { 'https://site.example/cache-reset' }

  def call_tool(name, arguments = {})
    post '/mcp', params: { jsonrpc: '2.0', method: 'tools/call', id: 1,
                           params: { name: name, arguments: arguments } }.to_json, headers: headers
    JSON.parse(response.parsed_body.dig('result', 'content', 0, 'text'))
  end

  around do |example|
    original = ENV.values_at('WEBSITE_URL', 'CACHE_RESET_TOKEN')
    ENV['WEBSITE_URL'] = 'https://site.example'
    ENV['CACHE_RESET_TOKEN'] = 'tok'
    FileUtils.rm_f(WebsiteCacheReset::DEFAULT_STAMP_PATH)
    example.run
    ENV['WEBSITE_URL'], ENV['CACHE_RESET_TOKEN'] = original
    FileUtils.rm_f(WebsiteCacheReset::DEFAULT_STAMP_PATH)
  end

  it 'refreshes the site it is configured against' do
    stub_request(:get, endpoint).with(query: { token: 'tok' }).to_return(status: 200)

    answer = call_tool('refresh_website_cache')

    expect(answer['status']).to eq('ok')
    expect(answer['message']).to include('https://site.example')
  end

  it 'skips the call instead of hammering the site when asked again right away' do
    stub_request(:get, endpoint).with(query: { token: 'tok' }).to_return(status: 200)
    call_tool('refresh_website_cache')

    answer = call_tool('refresh_website_cache')

    expect(answer['status']).to eq('skipped')
    expect(WebMock).to have_requested(:get, endpoint).with(query: { token: 'tok' }).once
  end

  it 'takes no arguments, and says so' do
    answer = call_tool('refresh_website_cache', { force: true })

    expect(answer['status']).to eq('error')
    expect(answer['errors'].first).to include('force')
  end
end

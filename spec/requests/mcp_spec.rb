# frozen_string_literal: true

require 'rails_helper'

# The MCP server itself: JSON-RPC over Streamable HTTP at /mcp, with the article
# tools answering under the same permissions as the admin screens.
RSpec.describe 'MCP server', type: :request do
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

  def rpc(method, params = nil, id: 1)
    { jsonrpc: '2.0', method: method, id: id, params: params }.compact.to_json
  end

  def call_tool(name, arguments = {}, id: 1)
    post '/mcp', params: rpc('tools/call', { name: name, arguments: arguments }, id: id), headers: headers
    response.parsed_body
  end

  it 'handshakes and lists the article tools' do
    post '/mcp', params: rpc('initialize', { protocolVersion: '2025-03-26', capabilities: {},
                                             clientInfo: { name: 'claude', version: '1' } }), headers: headers
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['result']).to include('serverInfo', 'capabilities')

    post '/mcp', params: { jsonrpc: '2.0', method: 'notifications/initialized' }.to_json, headers: headers
    expect(response).to have_http_status(:accepted)

    post '/mcp', params: rpc('tools/list', nil, id: 2), headers: headers
    expect(response.parsed_body['result']['tools'].pluck('name')).to include('list_articles', 'get_article')

    get '/mcp', headers: headers
    expect(response).to have_http_status(:method_not_allowed)
  end

  it 'lists articles with filters and reads one in full' do
    create(:article, title: 'Kanban en equipos', lang: 'es', published: true)
    create(:article, title: 'Draft about Scrum', lang: 'en', published: false)

    listing = JSON.parse(call_tool('list_articles').dig('result', 'content', 0, 'text'))
    expect(listing).to include('returned' => 2, 'total' => 2)
    expect(listing).not_to include('truncated')

    published = JSON.parse(call_tool('list_articles', { published: true }).dig('result', 'content', 0, 'text'))
    expect(published['articles'].pluck('title')).to eq(['Kanban en equipos'])

    matched = JSON.parse(call_tool('list_articles', { query: 'Scrum' }).dig('result', 'content', 0, 'text'))
    expect(matched['articles'].pluck('title')).to eq(['Draft about Scrum'])

    article = create(:article, title: 'Full text', body: 'The whole body')
    fetched = JSON.parse(call_tool('get_article', { id: article.slug }).dig('result', 'content', 0, 'text'))
    expect(fetched).to include('slug' => article.slug, 'body' => 'The whole body')

    missing = JSON.parse(call_tool('get_article', { id: 'no-such-article' }).dig('result', 'content', 0, 'text'))
    expect(missing['error']).to eq('not_found')
  end

  it 'refuses a token whose user has no roles, the way the admin screens do' do
    user.roles.destroy_all
    create(:article)

    expect(call_tool('list_articles').to_s).to include('Unauthorized')
  end

  it 'refuses a revoked token' do
    token = Doorkeeper::AccessToken.by_token(access_token)
    token.revoke

    post '/mcp', params: rpc('tools/list'), headers: headers
    expect(response).to have_http_status(:unauthorized)
  end
end

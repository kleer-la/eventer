# frozen_string_literal: true

require 'rails_helper'

# Publishing news over MCP follows the same rule as articles: a content user
# drafts and edits, a publisher makes it visible (kleer-la/eventer#195).
RSpec.describe 'MCP news publishing', type: :request do
  let(:oauth_application) do
    Doorkeeper::Application.create!(name: 'Claude', redirect_uri: 'https://claude.ai/api/mcp/auth_callback',
                                    scopes: 'mcp', confidential: false)
  end
  let(:headers) do
    token = Doorkeeper::AccessToken.create!(application: oauth_application, resource_owner_id: user.id,
                                            scopes: 'mcp', expires_in: 2.hours, use_refresh_token: true)
    { 'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'application/json, text/event-stream',
      'HTTP_AUTHORIZATION' => "Bearer #{token.plaintext_token}" }
  end
  let!(:news) { create(:news, published: false) }

  def call_tool(name, arguments = {})
    post '/mcp', params: { jsonrpc: '2.0', method: 'tools/call', id: 1,
                           params: { name: name, arguments: arguments } }.to_json, headers: headers
    raw = response.parsed_body.dig('result', 'content', 0, 'text')
    raw.present? ? JSON.parse(raw) : response.parsed_body
  end

  context 'as a content user' do
    let(:user) { create(:content_user) }

    it 'edits the news but refuses to publish it' do
      expect(call_tool('news', { operation: 'update', id: news.id, title: 'Editada', confirm: true })['status'])
        .to eq('saved')

      result = call_tool('news', { operation: 'update', id: news.id, published: true, confirm: true })
      expect(result['status']).to eq('error')
      expect(result['errors'].join).to match(/not allowed/i)
      expect(news.reload.published).to be(false)
    end
  end

  context 'as a publisher' do
    let(:user) { create(:publisher_user) }

    it 'publishes the news and warns that it becomes visible' do
      result = call_tool('news', { operation: 'update', id: news.id, published: true, confirm: true })
      expect(result['status']).to eq('saved')
      expect(result['warnings'].join).to include('publicly visible')
      expect(news.reload.published).to be(true)
    end
  end
end

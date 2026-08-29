# frozen_string_literal: true

require 'rails_helper'

# Creating and editing articles over MCP: preview first, save on confirm, and
# the same publishing rule the admin screens enforce.
RSpec.describe 'MCP article writes', type: :request do
  let(:user) { create(:administrator) }
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

  def call_tool(name, arguments = {})
    post '/mcp', params: { jsonrpc: '2.0', method: 'tools/call', id: 1,
                           params: { name: name, arguments: arguments } }.to_json, headers: headers
    raw = response.parsed_body.dig('result', 'content', 0, 'text')
    raw.present? ? JSON.parse(raw) : response.parsed_body
  end

  describe 'create_article' do
    let(:fields) { { title: 'Nuevo artículo', description: 'Un resumen corto', body: 'El cuerpo' } }

    it 'previews without saving and saves on confirm' do
      result = call_tool('create_article', fields)
      expect(result['status']).to eq('preview')
      expect(result['changes']).to include('title')
      expect(Article.count).to eq(0)

      result = call_tool('create_article', fields.merge(confirm: true))
      expect(result['status']).to eq('saved')
      expect(Article.find(result['id']).title).to eq('Nuevo artículo')
      expect(Article.last.published).to be(false)
    end

    it 'reports validation errors instead of saving' do
      result = call_tool('create_article', fields.merge(description: 'x' * 200, confirm: true))
      expect(result['status']).to eq('error')
      # The app runs in Spanish, so match the field rather than the translated text
      expect(result['errors'].join).to include('Description')
      expect(Article.count).to eq(0)
    end

    it 'rejects an unknown category and names the existing ones' do
      create(:category, name: 'Agilidad')
      result = call_tool('create_article', fields.merge(category: 'No existe', confirm: true))
      expect(result['status']).to eq('error')
      expect(result['errors'].join).to include('Agilidad')
    end
  end

  describe 'update_article' do
    let!(:article) { create(:article, title: 'Viejo título', body: 'Cuerpo viejo', published: false) }

    it 'summarises a body change in the preview and applies it on confirm' do
      result = call_tool('update_article', { id: article.slug, body: 'Cuerpo nuevo y más largo' })
      expect(result['status']).to eq('preview')
      expect(result['changes']['body']).to include('from_length', 'to_length', 'new_beginning')
      expect(result['warnings'].join).to include('audio')
      expect(article.reload.body).to eq('Cuerpo viejo')

      result = call_tool('update_article', { id: article.slug, body: 'Cuerpo nuevo y más largo', confirm: true })
      expect(result['status']).to eq('saved')
      expect(article.reload.body).to eq('Cuerpo nuevo y más largo')
    end

    it 'answers an error for an unknown article' do
      expect(call_tool('update_article', { id: 'no-such-article' })['errors'].join).to include('no-such-article')
    end
  end

  describe 'publishing rights' do
    let!(:article) { create(:article, published: false) }

    context 'as a content user' do
      let(:user) { create(:content_user) }

      it 'edits the article but refuses to publish it' do
        expect(call_tool('update_article', { id: article.slug, title: 'Editado', confirm: true })['status'])
          .to eq('saved')

        result = call_tool('update_article', { id: article.slug, published: true, confirm: true })
        expect(result['status']).to eq('error')
        expect(result['errors'].join).to match(/not allowed/i)
        expect(article.reload.published).to be(false)
      end
    end

    context 'as a publisher' do
      let(:user) { create(:publisher_user) }

      it 'publishes the article and warns that it becomes visible' do
        result = call_tool('update_article', { id: article.slug, published: true, confirm: true })
        expect(result['status']).to eq('saved')
        expect(result['warnings'].join).to include('publicly visible')
        expect(article.reload.published).to be(true)
      end
    end
  end
end

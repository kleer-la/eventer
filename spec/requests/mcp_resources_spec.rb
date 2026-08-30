# frozen_string_literal: true

require 'rails_helper'

# Resource tools over MCP: listing, reading in full, creating and editing, with
# the same publishing rule the admin screens enforce.
RSpec.describe 'MCP resource tools', type: :request do
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

  describe 'list_resources' do
    it 'filters by format, title and published' do
      create(:resource, title_es: 'Canvas de propuesta', format: :canvas, published: true)
      create(:resource, title_es: 'Libro de agilidad', format: :book, published: false)

      expect(call_tool('list_resources')['count']).to eq(2)
      expect(call_tool('list_resources', { format: 'canvas' })['resources'].pluck('title_es'))
        .to eq(['Canvas de propuesta'])
      expect(call_tool('list_resources', { query: 'agilidad' })['resources'].pluck('title_es'))
        .to eq(['Libro de agilidad'])
      expect(call_tool('list_resources', { published: false })['resources'].pluck('title_es'))
        .to eq(['Libro de agilidad'])
    end

    it 'names the valid formats when given one it does not know' do
      result = call_tool('list_resources', { format: 'ebook' })
      expect(result['status']).to eq('error')
      expect(result['errors'].join).to include('infographic')
    end
  end

  describe 'get_resource' do
    it 'returns both language sides and what it recommends' do
      resource = create(:resource, title_es: 'Guía', title_en: 'Guide', getit_es: 'https://x/get.pdf')
      article = create(:article, title: 'Artículo recomendado')
      resource.recommended_contents.create!(target: article, relevance_order: 120)

      result = call_tool('get_resource', { id: resource.slug })

      expect(result['es']).to include('title' => 'Guía', 'getit' => 'https://x/get.pdf')
      expect(result['en']['title']).to eq('Guide')
      expect(result['downloadable']).to be(true)
      expect(result['recommends'].first).to include('target' => 'Artículo recomendado', 'relevance_order' => 120)
    end

    it 'answers an error for one that does not exist' do
      expect(call_tool('get_resource', { id: 'no-existe' })['errors'].join).to include('no-existe')
    end
  end

  describe 'create_resource' do
    let(:fields) { { title_es: 'Nuevo canvas', description_es: 'Un resumen', format: 'canvas' } }

    it 'previews without saving and saves on confirm, unpublished' do
      result = call_tool('create_resource', fields)
      expect(result['status']).to eq('preview')
      expect(result['warnings'].join).to include('untranslated')
      expect(Resource.count).to eq(0)

      result = call_tool('create_resource', fields.merge(confirm: true))
      expect(result['status']).to eq('saved')
      expect(Resource.find(result['id']).format).to eq('canvas')
      expect(Resource.last.published).to be_falsey
    end

    it 'rejects a format that is not in the enum' do
      result = call_tool('create_resource', fields.merge(format: 'ebook', confirm: true))
      expect(result['status']).to eq('error')
      expect(Resource.count).to eq(0)
    end

    it 'reports validation errors instead of saving' do
      result = call_tool('create_resource', fields.merge(description_es: 'x' * 300, confirm: true))
      expect(result['status']).to eq('error')
      expect(result['errors'].join).to include('Description es')
      expect(Resource.count).to eq(0)
    end
  end

  describe 'update_resource' do
    let!(:resource) { create(:resource, title_es: 'Viejo', published: false) }

    it 'summarises long fields and applies the change on confirm' do
      result = call_tool('update_resource', { id: resource.slug, long_description_es: 'Texto largo nuevo' })
      expect(result['changes']['long_description_es']).to include('from_length', 'to_length')

      call_tool('update_resource', { id: resource.slug, title_en: 'New', confirm: true })
      expect(resource.reload.title_en).to eq('New')
    end

    context 'as a content user' do
      let(:user) { create(:content_user) }

      it 'edits but refuses to publish' do
        expect(call_tool('update_resource', { id: resource.slug, title_es: 'Editado', confirm: true })['status'])
          .to eq('saved')

        result = call_tool('update_resource', { id: resource.slug, published: true, confirm: true })
        expect(result['status']).to eq('error')
        expect(result['errors'].join).to match(/not allowed/i)
        expect(resource.reload.published).to be_falsey
      end
    end
  end
end

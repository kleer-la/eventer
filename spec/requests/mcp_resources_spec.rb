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

      expect(call_tool('resources')['returned']).to eq(2)
      expect(call_tool('resources', { operation: 'list', format: 'canvas' })['resources'].pluck('title_es'))
        .to eq(['Canvas de propuesta'])
      expect(call_tool('resources', { operation: 'list', query: 'agilidad' })['resources'].pluck('title_es'))
        .to eq(['Libro de agilidad'])
      expect(call_tool('resources', { operation: 'list', published: false })['resources'].pluck('title_es'))
        .to eq(['Libro de agilidad'])
    end

    it 'names the valid formats when given one it does not know' do
      result = call_tool('resources', { operation: 'list', format: 'ebook' })
      expect(result['status']).to eq('error')
      expect(result['errors'].join).to include('infographic')
    end
  end

  describe 'get_resource' do
    it 'returns both language sides and what it recommends' do
      resource = create(:resource, title_es: 'Guía', title_en: 'Guide', getit_es: 'https://x/get.pdf')
      article = create(:article, title: 'Artículo recomendado')
      resource.recommended_contents.create!(target: article, relevance_order: 120)

      result = call_tool('resources', { operation: 'get', id: resource.slug })

      expect(result['es']).to include('title' => 'Guía', 'getit' => 'https://x/get.pdf')
      expect(result['en']['title']).to eq('Guide')
      expect(result['downloadable']).to be(true)
      expect(result['recommends'].first).to include('target' => 'Artículo recomendado', 'relevance_order' => 120)
    end

    it 'answers an error for one that does not exist' do
      expect(call_tool('resources', { operation: 'get', id: 'no-existe' })['errors'].join).to include('no-existe')
    end
  end

  describe 'create_resource' do
    let(:fields) { { title_es: 'Nuevo canvas', description_es: 'Un resumen', format: 'canvas' } }

    it 'previews without saving and saves on confirm, unpublished' do
      result = call_tool('resources', fields.merge(operation: 'create'))
      expect(result['status']).to eq('preview')
      expect(result['warnings'].join).to include('untranslated')
      expect(Resource.count).to eq(0)

      result = call_tool('resources', fields.merge(operation: 'create', confirm: true))
      expect(result['status']).to eq('saved')
      expect(Resource.find(result['id']).format).to eq('canvas')
      expect(Resource.last.published).to be_falsey
    end

    it 'takes the SEO fields too, like update_resource' do
      call_tool('resources', { operation: 'create', title_es: 'Con SEO', description_es: 'd', format: 'guide', slug: 'con-seo',
                                     tabtitle_es: 'Pestaña', seo_description_es: 'Meta', confirm: true })

      expect(Resource.find_by(slug: 'con-seo')).to have_attributes(tabtitle_es: 'Pestaña', seo_description_es: 'Meta')
    end

    it 'rejects a format that is not in the enum' do
      result = call_tool('resources', fields.merge(operation: 'create', format: 'ebook', confirm: true))
      expect(result['status']).to eq('error')
      expect(Resource.count).to eq(0)
    end

    it 'reports validation errors instead of saving' do
      result = call_tool('resources', fields.merge(operation: 'create', description_es: 'x' * 300, confirm: true))
      expect(result['status']).to eq('error')
      expect(result['errors'].join).to include('Description es')
      expect(Resource.count).to eq(0)
    end
  end

  describe 'update_resource' do
    let!(:resource) { create(:resource, title_es: 'Viejo', published: false) }

    it 'summarises long fields and applies the change on confirm' do
      result = call_tool('resources', { operation: 'update', id: resource.slug, long_description_es: 'Texto largo nuevo' })
      expect(result['changes']['long_description_es']).to include('from_length', 'to_length')

      call_tool('resources', { operation: 'update', id: resource.slug, title_en: 'New', confirm: true })
      expect(resource.reload.title_en).to eq('New')
    end

    it 'clears a link or a metadata field when given an empty string' do
      resource.update!(getit_es: 'https://x.example/file.pdf', landing_en: 'https://x.example/page', tags_es: 'a, b')

      result = call_tool('resources', { operation: 'update', id: resource.slug, getit_es: '', landing_en: '', tags_es: '', confirm: true })

      expect(result['status']).to eq('saved')
      expect(resource.reload).to have_attributes(getit_es: '', landing_en: '', tags_es: '')
    end

    it 'still refuses an empty Spanish title' do
      post '/mcp', params: { jsonrpc: '2.0', method: 'tools/call', id: 1,
                             params: { name: 'resources',
                                       arguments: { operation: 'update', id: resource.slug, title_es: '',
                                                    confirm: true } } }.to_json,
                   headers: headers

      expect(response.parsed_body.dig('result', 'isError')).to be(true)
      expect(response.parsed_body.dig('result', 'content', 0, 'text')).to include('title_es')
      expect(resource.reload.title_es).to eq('Viejo')
    end

    it 'tells what the site does with each link' do
      post '/mcp', params: { jsonrpc: '2.0', method: 'tools/list', id: 1 }.to_json, headers: headers
      tools = response.parsed_body.dig('result', 'tools').index_by { |t| t['name'] }

      properties = tools['resources'].dig('inputSchema', 'properties')
      expect(properties.dig('getit_es', 'description')).to match(/download form/i)
      expect(properties.dig('landing_es', 'description')).to match(/button/i)
    end

    context 'as a content user' do
      let(:user) { create(:content_user) }

      it 'edits but refuses to publish' do
        expect(call_tool('resources', { operation: 'update', id: resource.slug, title_es: 'Editado', confirm: true })['status'])
          .to eq('saved')

        result = call_tool('resources', { operation: 'update', id: resource.slug, published: true, confirm: true })
        expect(result['status']).to eq('error')
        expect(result['errors'].join).to match(/not allowed/i)
        expect(resource.reload.published).to be_falsey
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

# Cross references between entities over MCP. The permission that governs them
# is the right to update the *source*, the same as editing them as nested
# attributes in the admin.
RSpec.describe 'MCP recommendation tools', type: :request do
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

  let(:article) { create(:article, title: 'Artículo fuente') }
  let(:resource) { create(:resource, title_es: 'Canvas recomendado') }

  describe 'add_recommendation' do
    it 'previews without saving, then links the two on confirm' do
      arguments = { source_type: 'Article', source_id: article.slug,
                    target_type: 'Resource', target_id: resource.slug, relevance_order: 120 }

      result = call_tool('add_recommendation', arguments)
      expect(result['status']).to eq('preview')
      expect(result['recommendation']).to include('target' => 'Canvas recomendado', 'level' => 'intermediate')
      expect(article.recommended_contents).to be_empty

      result = call_tool('add_recommendation', arguments.merge(confirm: true))
      expect(result['status']).to eq('saved')
      expect(result['action']).to eq('added')
      expect(article.reload.recommended_contents.first.target).to eq(resource)
    end

    it 'defaults to relevance 50, which reads as the initial level' do
      call_tool('add_recommendation', { source_type: 'Article', source_id: article.slug,
                                        target_type: 'Resource', target_id: resource.slug, confirm: true })

      expect(article.reload.recommended_contents.first.relevance_order).to eq(50)
      listing = call_tool('list_recommendations', { source_type: 'Article', source_id: article.slug })
      expect(listing['recommends'].first['level']).to eq('initial')
    end

    it 'reorders instead of duplicating when the link already exists' do
      article.recommended_contents.create!(target: resource, relevance_order: 50)

      result = call_tool('add_recommendation', { source_type: 'Article', source_id: article.slug,
                                                 target_type: 'Resource', target_id: resource.slug,
                                                 relevance_order: 210, confirm: true })

      expect(result['action']).to eq('reordered')
      expect(article.reload.recommended_contents.count).to eq(1)
      expect(article.recommended_contents.first.relevance_order).to eq(210)
      expect(result['recommendation']['level']).to eq('advanced')
    end

    it 'says so when the same link and order is asked for twice' do
      article.recommended_contents.create!(target: resource, relevance_order: 50)

      result = call_tool('add_recommendation', { source_type: 'Article', source_id: article.slug,
                                                 target_type: 'Resource', target_id: resource.slug,
                                                 relevance_order: 50, confirm: true })
      expect(result['errors'].join).to include('already recommended')
    end

    it 'finds the entities by slug, id or name' do
      by_id = call_tool('add_recommendation', { source_type: 'Article', source_id: article.id.to_s,
                                                target_type: 'Resource', target_id: resource.title_es })
      expect(by_id['status']).to eq('preview')
      expect(by_id['source']['label']).to eq('Artículo fuente')
    end

    it 'rejects a type that cannot be a target' do
      # The type is checked before anything is looked up, so no record is needed.
      result = call_tool('add_recommendation', { source_type: 'Article', source_id: article.slug,
                                                 target_type: 'Podcast', target_id: 'kleer-podcast' })
      expect(result['errors'].join).to include('is not one of')
    end

    it 'reports an entity it cannot find' do
      result = call_tool('add_recommendation', { source_type: 'Article', source_id: 'no-existe',
                                                 target_type: 'Resource', target_id: resource.slug })
      expect(result['errors'].join).to include('No Article matching')
    end
  end

  describe 'list_recommendations' do
    it 'lists them in relevance order with the level of each' do
      other = create(:resource, title_es: 'Libro avanzado')
      article.recommended_contents.create!(target: resource, relevance_order: 210)
      article.recommended_contents.create!(target: other, relevance_order: 30)

      result = call_tool('list_recommendations', { source_type: 'Article', source_id: article.slug })

      expect(result['count']).to eq(2)
      expect(result['recommends'].pluck('relevance_order')).to eq([30, 210])
      expect(result['recommends'].pluck('level')).to eq(%w[initial advanced])
    end
  end

  describe 'remove_recommendation' do
    before { article.recommended_contents.create!(target: resource, relevance_order: 50) }

    it 'previews, then removes only the link' do
      arguments = { source_type: 'Article', source_id: article.slug,
                    target_type: 'Resource', target_id: resource.slug }

      expect(call_tool('remove_recommendation', arguments)['status']).to eq('preview')
      expect(article.reload.recommended_contents.count).to eq(1)

      expect(call_tool('remove_recommendation', arguments.merge(confirm: true))['action']).to eq('removed')
      expect(article.reload.recommended_contents).to be_empty
      expect(Resource.find_by(id: resource.id)).to be_present
    end

    it 'says so when the link is not there' do
      other = create(:resource, title_es: 'No relacionado')
      result = call_tool('remove_recommendation', { source_type: 'Article', source_id: article.slug,
                                                    target_type: 'Resource', target_id: other.slug })
      expect(result['errors'].join).to include('is not recommended by')
    end
  end

  describe 'pages as a target' do
    let(:page) { create(:page, name: 'Membresía IA', lang: :es, template: 'flagship', slug: 'membresia-ia') }

    it 'recommends a flagship page from an article' do
      result = call_tool('add_recommendation', { source_type: 'Article', source_id: article.slug,
                                                 target_type: 'Page', target_id: page.slug, confirm: true })

      expect(result['status']).to eq('saved')
      expect(article.reload.recommended_contents.first.target).to eq(page)
    end

    it 'gives the page a card without the language suffix the admin label carries' do
      card = page.as_recommendation

      expect(card['title']).to eq('Membresía IA')
      expect(card['type']).to eq('page')
      expect(card['slug']).to eq('membresia-ia')
    end

    it 'refuses an overlay page: it has no URL of its own to link to' do
      overlay = create(:page, name: 'Contacto', lang: :es, template: 'overlay')

      result = call_tool('add_recommendation', { source_type: 'Article', source_id: article.slug,
                                                 target_type: 'Page', target_id: overlay.slug, confirm: true })

      expect(result['errors'].join).to include('overlay page')
      expect(article.reload.recommended_contents).to be_empty
    end

    it 'offers only flagship pages in the admin picker' do
      flagship = page
      create(:page, name: 'Contacto', lang: :es, template: 'overlay')

      expect(Article.recommended_content_targets['Page']).to eq([[flagship.display_name, flagship.id]])
    end
  end

  describe 'permissions' do
    let(:user) { create(:content_user) }

    it 'follows what the user may edit in the source, not the link itself' do
      result = call_tool('add_recommendation', { source_type: 'Article', source_id: article.slug,
                                                 target_type: 'Resource', target_id: resource.slug,
                                                 confirm: true })
      expect(result['status']).to eq('saved')

      service = create(:service)
      result = call_tool('add_recommendation', { source_type: 'Service', source_id: service.slug,
                                                 target_type: 'Resource', target_id: resource.slug,
                                                 confirm: true })
      expect(result['errors'].join).to match(/not allowed to edit/i)
      expect(service.reload.recommended_contents).to be_empty
    end
  end
end

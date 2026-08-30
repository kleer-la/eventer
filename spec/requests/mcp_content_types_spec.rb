# frozen_string_literal: true

require 'rails_helper'

# Services, pages, podcasts and news over MCP. They differ from articles in ways
# the shared write service has to absorb: some say "visible" instead of
# "published", some have no such flag, some have no slug, and several keep their
# main text in ActionText.
RSpec.describe 'MCP tools for the other content types', type: :request do
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

  describe 'news' do
    it 'lists, filters and reads one by id' do
      visible = create(:news, title: 'Charla en Buenos Aires', visible: true)
      create(:news, title: 'Borrador interno', visible: false)

      expect(call_tool('list_news')['count']).to eq(2)
      expect(call_tool('list_news', { visible: true })['news'].pluck('title')).to eq(['Charla en Buenos Aires'])
      expect(call_tool('get_news_item', { id: visible.id })['where']).to eq('Buenos Aires, Argentina')
      expect(call_tool('get_news_item', { id: 0 })['errors'].join).to include('No news item')
    end

    it 'creates hidden by default and shows it only when asked' do
      result = call_tool('create_news', { title: 'Nueva charla' })
      expect(result['status']).to eq('preview')
      expect(News.count).to eq(0)

      result = call_tool('create_news', { title: 'Nueva charla', confirm: true })
      expect(result['status']).to eq('saved')
      expect(News.last.visible).to be(false)

      call_tool('update_news', { id: News.last.id, visible: true, confirm: true })
      expect(News.last.visible).to be(true)
    end

    context 'as a content user' do
      let(:user) { create(:content_user) }

      it 'may show a news item: unlike articles, visibility carries no separate permission' do
        item = create(:news, visible: false)
        result = call_tool('update_news', { id: item.id, visible: true, confirm: true })

        expect(result['status']).to eq('saved')
        expect(item.reload.visible).to be(true)
      end
    end
  end

  describe 'podcasts and episodes' do
    it 'creates a podcast, summarises its rich-text description, and adds episodes' do
      result = call_tool('create_podcast', { title: 'Kleer Podcast', description: '<p>Sobre agilidad</p>' })
      expect(result['changes']['description']).to include('to_length', 'new_beginning')

      podcast_id = call_tool('create_podcast', { title: 'Kleer Podcast', description: '<p>Sobre agilidad</p>',
                                                 confirm: true })['id']
      expect(Podcast.find(podcast_id).description_body).to include('Sobre agilidad')

      episode = { podcast_id: podcast_id, title: 'Piloto', description: '<p>Primero</p>',
                  season: 1, episode: 1, published_at: '2026-08-01' }
      expect(call_tool('create_episode', episode.merge(confirm: true))['status']).to eq('saved')

      listing = call_tool('get_podcast', { id: podcast_id })
      expect(listing['episodes'].first).to include('season' => 1, 'episode' => 1, 'title' => 'Piloto')
      expect(call_tool('list_podcasts')['podcasts'].first['episodes']).to eq(1)
    end

    it 'warns before repeating a season and episode number' do
      podcast = Podcast.create!(title: 'Kleer Podcast', description: '<p>x</p>')
      podcast.episodes.create!(title: 'Piloto', description: '<p>x</p>', season: 1, episode: 1,
                               published_at: Date.new(2026, 8, 1))

      result = call_tool('create_episode', { podcast_id: podcast.id, title: 'Repetido',
                                             description: '<p>y</p>', season: 1, episode: 1,
                                             published_at: '2026-08-08' })

      expect(result['warnings'].join).to include('already exists')
    end
  end

  describe 'services' do
    let!(:service) { create(:service, name: 'Formación en Scrum', visible: false) }

    it 'lists, and returns the rich-text blocks as HTML' do
      expect(call_tool('list_services')['services'].pluck('name')).to eq(['Formación en Scrum'])

      result = call_tool('get_service', { id: service.slug })
      expect(result['blocks']['outcomes']).to include('<li>one</li>')
      expect(result['service_area']).to be_present
    end

    it 'previews a rich-text block as a summary and saves it on confirm' do
      result = call_tool('update_service', { id: service.slug, value_proposition: '<p>Nueva propuesta</p>' })
      expect(result['changes']['value_proposition']).to include('new_beginning')
      expect(service.reload.value_proposition.body.to_s).to include('Default value_proposition')

      call_tool('update_service', { id: service.slug, value_proposition: '<p>Nueva propuesta</p>', confirm: true })
      expect(service.reload.value_proposition.body.to_s).to include('Nueva propuesta')
    end

    it 'rejects a service area it does not know, naming the ones that exist' do
      result = call_tool('update_service', { id: service.slug, service_area: 'No existe', confirm: true })
      expect(result['status']).to eq('error')
      expect(result['errors'].join).to include(ServiceArea.first.name)
    end

    context 'as a content user' do
      let(:user) { create(:content_user) }

      it 'cannot touch services: they are not among the content models' do
        expect(call_tool('update_service', { id: service.slug, name: 'Otro', confirm: true }).to_s)
          .to include('Unauthorized')
      end
    end
  end

  describe 'pages' do
    it 'lists by template and reports an unknown one' do
      create(:page, name: 'Home', lang: :es, template: 'overlay')
      create(:page, name: 'Landing', lang: :es, template: 'flagship')

      expect(call_tool('list_pages', { template: 'flagship' })['pages'].pluck('name')).to eq(['Landing'])
      expect(call_tool('list_pages', { template: 'inventado' })['errors'].join).to include('overlay')
    end

    it 'creates a page and returns its sections when read' do
      result = call_tool('create_page', { name: 'Nueva landing', lang: 'es', template: 'flagship',
                                          confirm: true })
      expect(result['status']).to eq('saved')

      page = Page.find(result['id'])
      page.sections.create!(title: 'Intro', position: 1, content: 'Hola')

      read = call_tool('get_page', { id: page.id })
      expect(read['template']).to eq('flagship')
      expect(read['sections'].first).to include('title' => 'Intro', 'position' => 1)
    end

    it 'allows the same slug in each language' do
      call_tool('create_page', { name: 'Contacto', lang: 'es', slug: 'contacto', confirm: true })
      result = call_tool('create_page', { name: 'Contact', lang: 'en', slug: 'contacto', confirm: true })

      expect(result['status']).to eq('saved')
      expect(Page.where(slug: 'contacto').count).to eq(2)
    end
  end
end

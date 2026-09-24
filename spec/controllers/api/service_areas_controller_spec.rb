# frozen_string_literal: true

require 'rails_helper'

describe Api::ServiceAreasController do
  describe "GET 'index'" do
    before do
      @regular_service = FactoryBot.create(:service_area, visible: true, is_training_program: false)
      @training_program = FactoryBot.create(:service_area, visible: true, is_training_program: true)
    end

    it 'shows only regular services in /services.json' do
      get :index, params: { format: 'json' }
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      service_slugs = json_response.map { |sa| sa['slug'] }
      expect(service_slugs).to include(@regular_service.slug)
      expect(service_slugs).not_to include(@training_program.slug)
    end

    it 'shows only training programs in /programs.json' do
      get :programs, params: { format: 'json' }
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      program_slugs = json_response.map { |sa| sa['slug'] }
      expect(program_slugs).to include(@training_program.slug)
      expect(program_slugs).not_to include(@regular_service.slug)
    end

    it 'exposes ordering on each item in the list' do
      get :index, params: { format: 'json' }
      json_response = JSON.parse(response.body)
      expect(json_response.first).to have_key('ordering')
      expect(json_response.first['ordering']).to eq(@regular_service.ordering)
    end

    # The show endpoint filters these out and the list did not, so website17's
    # sitemap — which reads the list — declared a service page that answers 404.
    it 'lists only published services' do
      published = FactoryBot.create(:service, service_area: @regular_service, published: true)
      unpublished = FactoryBot.create(:service, service_area: @regular_service, published: false)

      get :index, params: { format: 'json' }
      services = JSON.parse(response.body).find { |sa| sa['slug'] == @regular_service.slug }['services']

      expect(services.map { |s| s['id'] }).to include(published.id)
      expect(services.map { |s| s['id'] }).not_to include(unpublished.id)
    end

    it 'lists only published services of a training programme' do
      unpublished = FactoryBot.create(:service, service_area: @training_program, published: false)

      get :programs, params: { format: 'json' }
      services = JSON.parse(response.body).find { |sa| sa['slug'] == @training_program.slug }['services']

      expect(services.map { |s| s['id'] }).not_to include(unpublished.id)
    end
  end

  describe "GET 'ServiceAreas/#' (/api/services/#.<format>)" do
    let(:service_area) { FactoryBot.create(:service_area) }
    let!(:visible_service) { FactoryBot.create(:service, service_area:, published: true) }
    let!(:invisible_service) { FactoryBot.create(:service, service_area:, published: false) }

    context 'fetch visible' do
      it 'fetch a ServiceArea' do
        get :show, params: { id: service_area.slug, format: 'json' }
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['slug']).to eq(service_area.slug)
      end
      it 'responds with error for unknown ServiceArea' do
        get :show, params: { id: 'unknown-slug', format: 'json' }
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('ServiceArea not found')
      end
      it 'fetches a ServiceArea by included Service slug' do
        get :show, params: { id: visible_service.slug, format: 'json' }
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['slug']).to eq(service_area.slug)
      end
      it 'shows only visible services' do
        get :show, params: { id: service_area.slug, format: 'json' }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        service_ids = json_response['services'].map { |s| s['id'] }

        expect(service_ids).to include(visible_service.id)
        expect(service_ids).not_to include(invisible_service.id)
      end
    end
    context 'preview endpoint' do
      it 'shows all services regardless of visibility' do
        get :preview, params: { id: service_area.slug, format: 'json' }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        service_ids = json_response['services'].map { |s| s['id'] }

        expect(service_ids).to include(visible_service.id)
        expect(service_ids).to include(invisible_service.id)
      end
    end
    describe 'value_proposition_title' do
      it 'exposes value_proposition_title when set' do
        sa = FactoryBot.create(:service_area, value_proposition_title: 'Por qué elegirnos')
        get :show, params: { id: sa.slug, format: 'json' }
        json_response = JSON.parse(response.body)
        expect(json_response['value_proposition_title']).to eq('Por qué elegirnos')
      end

      it 'returns nil value_proposition_title when not set' do
        get :show, params: { id: service_area.slug, format: 'json' }
        json_response = JSON.parse(response.body)
        expect(json_response['value_proposition_title']).to be_nil
      end
    end

    describe 'SEO fields' do
      it 'includes seo_title and seo_description for services' do
        service = FactoryBot.create(:service, service_area:, published: true,
                                              seo_title: 'Service SEO Title',
                                              seo_description: 'Service SEO Description')
        get :show, params: { id: service_area.slug, format: 'json' }
        json_response = JSON.parse(response.body)
        svc = json_response['services'].find { |s| s['id'] == service.id }
        expect(svc['seo_title']).to eq('Service SEO Title')
        expect(svc['seo_description']).to eq('Service SEO Description')
      end

      it 'returns nil seo fields when not set' do
        get :show, params: { id: service_area.slug, format: 'json' }
        json_response = JSON.parse(response.body)
        svc = json_response['services'].find { |s| s['id'] == visible_service.id }
        expect(svc['seo_title']).to be_nil
        expect(svc['seo_description']).to be_nil
      end
    end

    describe 'card_description field' do
      it 'exposes card_description on individual services when set' do
        service = FactoryBot.create(:service, service_area:, published: true,
                                              card_description: '<section class="rw-section"><h2>Programa</h2></section>')
        get :show, params: { id: service_area.slug, format: 'json' }
        json_response = JSON.parse(response.body)
        svc = json_response['services'].find { |s| s['id'] == service.id }
        expect(svc['card_description']).to include('Programa')
      end

      it 'returns nil card_description when not set' do
        get :show, params: { id: service_area.slug, format: 'json' }
        json_response = JSON.parse(response.body)
        svc = json_response['services'].find { |s| s['id'] == visible_service.id }
        expect(svc['card_description']).to be_nil
      end
    end

    describe 'Forma Recomendada fields (Markdown rendered to HTML)' do
      it 'exposes recommended way fields at area level when set' do
        sa = FactoryBot.create(:service_area,
                               recommended_way_title: 'Forma del Área',
                               recommended_way_note: '80% path',
                               recommended_way_summary: "## Paso 1\n\nAlgo",
                               recommended_way_details: "### Detalle completo\n\nMás")
        get :show, params: { id: sa.slug, format: 'json' }
        json_response = JSON.parse(response.body)
        expect(json_response['recommended_way_title']).to eq('Forma del Área')
        expect(json_response['recommended_way_note']).to eq('80% path')
        expect(json_response['recommended_way_summary']).to include('<h2>Paso 1</h2>')
        expect(json_response['recommended_way_summary']).to include('<p>Algo</p>')
        expect(json_response['recommended_way_details']).to include('<h3>Detalle completo</h3>')
        expect(json_response['recommended_way_details']).to include('<p>Más</p>')
      end

      it 'exposes recommended way fields on individual services' do
        service = FactoryBot.create(:service, service_area:, published: true,
                                    recommended_way_title: 'Forma del Servicio',
                                    recommended_way_summary: '- Paso A\n- Paso B')
        get :show, params: { id: service_area.slug, format: 'json' }
        json_response = JSON.parse(response.body)
        svc = json_response['services'].find { |s| s['id'] == service.id }
        expect(svc['recommended_way_title']).to eq('Forma del Servicio')
        expect(svc['recommended_way_summary']).to include('<ul>')
      end

      it 'returns nil recommended way fields when not set' do
        get :show, params: { id: service_area.slug, format: 'json' }
        json_response = JSON.parse(response.body)
        expect(json_response['recommended_way_title']).to be_nil
        expect(json_response['recommended_way_summary']).to be_nil
        svc = json_response['services'].find { |s| s['id'] == visible_service.id }
        expect(svc['recommended_way_details']).to be_nil
      end

      it 'passes raw HTML through untouched (HTML-first authoring)' do
        sa = FactoryBot.create(:service_area,
                               recommended_way_summary: %(<ul class="rw-steps">\n  <li class="rw-step">A</li>\n</ul>))
        get :show, params: { id: sa.slug, format: 'json' }
        json_response = JSON.parse(response.body)
        expect(json_response['recommended_way_summary']).to include('<ul class="rw-steps">')
        expect(json_response['recommended_way_summary']).to include('<li class="rw-step">A</li>')
      end

      it 'does not inject <br> for single newlines (hard_wrap disabled)' do
        sa = FactoryBot.create(:service_area,
                               recommended_way_details: "<div>\nlinea uno\nlinea dos\n</div>")
        get :show, params: { id: sa.slug, format: 'json' }
        json_response = JSON.parse(response.body)
        expect(json_response['recommended_way_details']).not_to include('<br')
      end
    end

    # An area can be an offering in itself — the same blocks a service has, so
    # the area page can present it and sell it without a service underneath.
    describe 'offering content on the area' do
      # Rich text renders through the view layer, which controller specs stub out
      render_views

      it 'exposes the service blocks at area level' do
        recommended = FactoryBot.create(:service, service_area:, name: 'Recomendado', published: true)
        sa = FactoryBot.create(:service_area,
                               outcomes: '<ul><li>Equipos alineados</li><li>Menos retrabajo</li></ul>',
                               program: '<ol><li>Diagnóstico<ul><li>Dos semanas</li></ul></li></ol>',
                               definitions: '<p>Qué entendemos por cambio</p>',
                               faq: '<ol><li>¿Cuánto dura?<ul><li>Tres meses</li></ul></li></ol>',
                               pricing: 'Desde USD 5.000',
                               brochure: 'https://example.com/brochure.pdf')
        FactoryBot.create(:recommended_content, source: sa, target: recommended, relevance_order: 1)

        get :show, params: { id: sa.slug, format: 'json' }
        json_response = JSON.parse(response.body)

        expect(json_response['outcomes']).to eq(['Equipos alineados', 'Menos retrabajo'])
        expect(json_response['program']).to eq([['Diagnóstico', 'Dos semanas']])
        expect(json_response['definitions']).to include('Qué entendemos por cambio')
        expect(json_response['faq']).to eq([['¿Cuánto dura?', 'Tres meses']])
        expect(json_response['pricing']).to eq('Desde USD 5.000')
        expect(json_response['brochure']).to eq('https://example.com/brochure.pdf')
        expect(json_response['recommended'].map { |r| r['title'] }).to eq(['Recomendado'])
      end

      it 'answers empty blocks when the area has none' do
        get :show, params: { id: service_area.slug, format: 'json' }
        json_response = JSON.parse(response.body)

        expect(json_response['outcomes']).to be_nil
        expect(json_response['program']).to eq([])
        expect(json_response['definitions']).to be_nil
        expect(json_response['faq']).to eq([])
        expect(json_response['pricing']).to be_nil
        expect(json_response['brochure']).to be_nil
        expect(json_response['recommended']).to eq([])
      end
    end

    # The area page shows what clients said about its services: the starred
    # testimonies, in the shape the course pages already read (fname/lname).
    describe 'testimonies on the area page' do
      render_views

      it 'sends the starred testimonies of its services, and only those' do
        sa = FactoryBot.create(:service_area)
        service = FactoryBot.create(:service, service_area: sa, published: true)
        FactoryBot.create(:testimony, :starred, testimonial: service, first_name: 'Ana', last_name: 'Pérez',
                                                testimony: '<p>Nos ordenó el backlog.</p>')
        FactoryBot.create(:testimony, testimonial: service, first_name: 'Sin', last_name: 'Estrella')

        get :show, params: { id: sa.slug, format: 'json' }
        testimonies = JSON.parse(response.body)['testimonies']

        expect(testimonies.size).to eq(1)
        expect(testimonies.first).to include('fname' => 'Ana', 'lname' => 'Pérez',
                                             'testimony' => 'Nos ordenó el backlog.',
                                             'profile_url' => 'https://linkedin.com/in/johndoe')
      end

      it 'sends an empty list when none is starred' do
        get :show, params: { id: service_area.slug, format: 'json' }

        expect(JSON.parse(response.body)['testimonies']).to eq([])
      end
    end

    # The hero and contact texts come from one Page shared by every area; an
    # area can bring its own, and the site falls back to the Page when it does not.
    describe 'page texts of its own' do
      it 'exposes the hero and contact texts the area sets' do
        sa = FactoryBot.create(:service_area,
                               hero_cta_text: 'Conversemos tu caso',
                               hero_secondary_cta_text: 'Ver cómo trabajamos',
                               hero_secondary_cta_target: '#como-trabajamos',
                               hero_note: 'Trabajamos dentro del equipo, no desde afuera.',
                               contact_title: 'Una conversación de 45 minutos',
                               contact_cta_text: 'Agendar')

        get :show, params: { id: sa.slug, format: 'json' }
        json_response = JSON.parse(response.body)

        expect(json_response).to include(
          'hero_cta_text' => 'Conversemos tu caso',
          'hero_secondary_cta_text' => 'Ver cómo trabajamos',
          'hero_secondary_cta_target' => '#como-trabajamos',
          'hero_note' => 'Trabajamos dentro del equipo, no desde afuera.',
          'contact_title' => 'Una conversación de 45 minutos',
          'contact_cta_text' => 'Agendar'
        )
      end

      it 'answers nil for the texts the area leaves to the shared page' do
        get :show, params: { id: service_area.slug, format: 'json' }
        json_response = JSON.parse(response.body)

        %w[hero_cta_text hero_secondary_cta_text hero_secondary_cta_target hero_note
           contact_title contact_cta_text].each do |field|
          expect(json_response).to include(field => nil)
        end
      end
    end

    describe 'Redirect' do
      before do
        @service_area = FactoryBot.create(:service_area)
        @service = FactoryBot.create(:service, service_area: @service_area, published: true)
      end

      it 'No slug changed (by ServiceArea)' do
        get :show, params: { id: @service_area.slug, format: 'json' }
        json_response = JSON.parse(response.body)
        expect(json_response['slug_old']).to be nil
        expect(json_response['services'][0]['slug_old']).to be nil
      end
      it 'No slug changed (by Service)' do
        get :show, params: { id: @service.slug, format: 'json' }
        json_response = JSON.parse(response.body)
        expect(json_response['slug_old']).to be nil
        expect(json_response['services'][0]['slug_old']).to be nil
      end
      it 'ServiceArea slug changed (by ServiceArea)' do
        old_slug = @service_area.slug
        @service_area.slug = 'new-slug'
        @service_area.save

        get :show, params: { id: old_slug, format: 'json' }
        json_response = JSON.parse(response.body)
        expect(json_response['slug_old']).to eq old_slug
        expect(json_response['services'][0]['slug_old']).to be nil
      end
      it 'ServiceArea slug changed (by Service)' do
        @service_area.slug = 'new-slug'
        @service_area.save

        get :show, params: { id: @service.slug, format: 'json' }
        json_response = JSON.parse(response.body)
        expect(json_response['slug_old']).to eq nil
        expect(json_response['services'][0]['slug_old']).to be nil
      end
      it 'Service slug changed (by ServiceArea)' do
        @service.slug = 'new-slug'
        @service.save

        get :show, params: { id: @service_area.slug, format: 'json' }
        json_response = JSON.parse(response.body)
        expect(json_response['slug_old']).to eq nil
        expect(json_response['services'][0]['slug_old']).to be nil
      end
      it 'Service slug changed (by Service)' do
        old_slug = @service.slug
        @service.slug = 'new-slug'
        @service.save

        get :show, params: { id: old_slug, format: 'json' }
        json_response = JSON.parse(response.body)
        expect(json_response['slug_old']).to eq nil
        expect(json_response['services'][0]['slug_old']).to eq old_slug
      end
    end
  end
end

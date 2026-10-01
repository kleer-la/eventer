# frozen_string_literal: true

require 'rails_helper'

# ServiceArea is not a content-role model — it is not in Ability::CONTENT_MODELS
# — so these tools need a role with a broader grant, same as the admin screens.
describe 'service area MCP tools' do
  let(:user) { FactoryBot.create(:marketing_user) }
  let(:service_area) { FactoryBot.create(:service_area, name: 'IA Aplicada', visible: false) }

  def run(tool_class, **args)
    tool = tool_class.new
    allow(tool).to receive_messages(current_user: user, ability: Ability.new(user))
    JSON.parse(tool.call(**args))
  end

  describe 'operation=create' do
    let(:required_fields) do
      { name: 'Agile Coaching', summary: 'summary', icon: 'https://example.com/icon.png',
        slogan: 'slogan', subtitle: 'subtitle', description: 'description',
        side_image: 'https://example.com/side.png', primary_color: '#68CEF2', secondary_color: '#68CEF2',
        cta_message: 'cta', seo_title: 'seo title', seo_description: 'seo description' }
    end

    it 'previews without saving' do
      result = run(ServiceAreasTool, operation: 'create', **required_fields)

      expect(result['status']).to eq 'preview'
      expect(ServiceArea.find_by(name: 'Agile Coaching')).to be_nil
    end

    it 'creates it hidden on confirm, unless told otherwise' do
      result = run(ServiceAreasTool, operation: 'create', **required_fields, confirm: true)

      area = ServiceArea.find(result['id'])
      expect(area.visible).to be false
    end

    it 'creates it visible when asked' do
      run(ServiceAreasTool, operation: 'create', **required_fields, confirm: true, visible: true)

      expect(ServiceArea.find_by(name: 'Agile Coaching').visible).to be true
    end
  end

  describe 'operation=get' do
    it 'returns the blocks that make up the page' do
      result = run(ServiceAreasTool, operation: 'get', id: service_area.slug)

      expect(result['name']).to eq 'IA Aplicada'
      expect(result['blocks']['summary']).to include 'summary'
    end

    it 'returns the offering blocks, pricing, brochure and what it recommends' do
      article = FactoryBot.create(:article, title: 'Lectura sugerida')
      service_area.update!(outcomes: '<ul><li>Equipos alineados</li></ul>', program: '<ol><li>Paso 1</li></ol>',
                           definitions: '<p>Definiciones</p>', faq: '<ol><li>¿Cuánto?</li></ol>',
                           pricing: 'Desde USD 5.000', brochure: 'https://example.com/b.pdf')
      FactoryBot.create(:recommended_content, source: service_area, target: article, relevance_order: 1)

      result = run(ServiceAreasTool, operation: 'get', id: service_area.slug)

      expect(result['blocks']['outcomes']).to include 'Equipos alineados'
      expect(result['blocks']['program']).to include 'Paso 1'
      expect(result['blocks']['definitions']).to include 'Definiciones'
      expect(result['blocks']['faq']).to include '¿Cuánto?'
      expect(result['pricing']).to eq 'Desde USD 5.000'
      expect(result['brochure']).to eq 'https://example.com/b.pdf'
      expect(result['recommends']).to eq [{ 'target_type' => 'Article', 'target_id' => article.id,
                                            'target' => 'Lectura sugerida', 'relevance_order' => 1 }]
    end

    it 'says so when there is no such service area' do
      result = run(ServiceAreasTool, operation: 'get', id: 'no-existe')

      expect(result['status']).to eq 'error'
      expect(result['errors'].first).to include 'no-existe'
    end
  end

  describe 'operation=update' do
    it 'previews without saving' do
      result = run(ServiceAreasTool, operation: 'update', id: service_area.slug, subtitle: 'Nuevo subtítulo')

      expect(result['status']).to eq 'preview'
      expect(service_area.reload.subtitle.to_s).to include 'subtitle'
      expect(service_area.subtitle.to_s).not_to include 'Nuevo subtítulo'
    end

    it 'saves on confirm' do
      run(ServiceAreasTool, operation: 'update', id: service_area.slug, subtitle: 'Nuevo subtítulo', confirm: true)

      expect(service_area.reload.subtitle.to_s).to include 'Nuevo subtítulo'
    end

    it 'writes the offering blocks, pricing and brochure' do
      run(ServiceAreasTool, operation: 'update', id: service_area.slug, confirm: true,
                            outcomes: '<ul><li>Equipos alineados</li></ul>', program: '<ol><li>Paso 1</li></ol>',
                            pricing: 'Desde USD 5.000', brochure: 'https://example.com/b.pdf')

      service_area.reload
      expect(service_area.outcomes_list).to eq ['Equipos alineados']
      expect(service_area.program_list).to eq [['Paso 1', nil]]
      expect(service_area.pricing).to eq 'Desde USD 5.000'
      expect(service_area.brochure).to eq 'https://example.com/b.pdf'
    end

    it 'reads back the hero and contact texts, nil where the area uses the shared ones' do
      service_area.update!(hero_cta_text: 'Conversemos tu caso')

      result = run(ServiceAreasTool, operation: 'get', id: service_area.slug)

      expect(result['page_texts']).to include('hero_cta_text' => 'Conversemos tu caso', 'contact_title' => nil,
                                              'contact_text' => nil)
    end

    it 'writes the hero and contact texts of the area' do
      run(ServiceAreasTool, operation: 'update', id: service_area.slug, confirm: true,
                            hero_cta_text: 'Conversemos tu caso', hero_secondary_cta_text: 'Ver cómo trabajamos',
                            hero_secondary_cta_target: '#como-trabajamos', hero_note: 'Dentro del equipo.',
                            contact_title: 'Empecemos por entender tu caso', contact_text: 'Una conversación de 45 minutos.',
                            contact_cta_text: 'Agendar')

      expect(service_area.reload).to have_attributes(
        hero_cta_text: 'Conversemos tu caso', hero_secondary_cta_text: 'Ver cómo trabajamos',
        hero_secondary_cta_target: '#como-trabajamos', hero_note: 'Dentro del equipo.',
        contact_title: 'Empecemos por entender tu caso', contact_text: 'Una conversación de 45 minutos.',
        contact_cta_text: 'Agendar'
      )
    end

    it 'writes and reads back the hero image' do
      run(ServiceAreasTool, operation: 'update', id: service_area.slug, confirm: true,
                            hero_image: 'https://example.com/hero.webp')

      result = run(ServiceAreasTool, operation: 'get', id: service_area.slug)

      expect(result['hero_image']).to eq 'https://example.com/hero.webp'
    end

    it 'writes and reads back the hero highlight' do
      run(ServiceAreasTool, operation: 'update', id: service_area.slug, confirm: true,
                            hero_highlight: '2 semanas', hero_highlight_text: 'de diagnóstico')

      result = run(ServiceAreasTool, operation: 'get', id: service_area.slug)

      expect(result).to include('hero_highlight' => '2 semanas', 'hero_highlight_text' => 'de diagnóstico')
    end

    it 'warns when the FAQ would not show on the page' do
      result = run(ServiceAreasTool, operation: 'update', id: service_area.slug,
                                     faq: '<h4>¿Cuánto dura?</h4><div>Tres meses</div>')

      expect(result['warnings']).to include(a_string_matching(/faq.*ol > li/m))
    end

    # Renaming moves every URL under the area; the preview says so (#208).
    it 'warns when the slug changes that the old URL will redirect and hand-written links will not' do
      result = run(ServiceAreasTool, operation: 'update', id: service_area.slug, slug: 'producto-digital')

      expect(result['warnings']).to include(
        a_string_matching(/slug changes from "ia-aplicada" to "producto-digital".*every service URL.*301.*by hand/)
      )
    end

    it 'does not warn about the slug when it stays' do
      result = run(ServiceAreasTool, operation: 'update', id: service_area.slug, name: 'IA Aplicada 2')

      expect(result['warnings'].to_s).not_to include('slug changes')
    end

    # An area that leaves takes its services with it, unless one has a
    # redirect of its own (#224).
    describe 'redirect_url' do
      it 'warns that the area and its services without a redirect of their own answer 301' do
        FactoryBot.create(:service, service_area: service_area, published: true)

        result = run(ServiceAreasTool, operation: 'update', id: service_area.slug, redirect_url: '/es/servicios/otra')

        expect(result['status']).to eq 'preview'
        expect(result['warnings'].join).to match(%r{301 to /es/servicios/otra.*1 service})
      end

      it 'saves it and reads it back' do
        run(ServiceAreasTool, operation: 'update', id: service_area.slug, redirect_url: '/es/servicios/otra',
                              confirm: true)

        expect(run(ServiceAreasTool, operation: 'get', id: service_area.slug)['redirect_url'])
          .to eq '/es/servicios/otra'
      end

      it 'suggests one when the area is hidden without it' do
        service_area.update!(visible: true)

        result = run(ServiceAreasTool, operation: 'update', id: service_area.slug, visible: false)

        expect(result['warnings'].join).to include('redirect_url')
      end
    end

    it 'can flip visible' do
      run(ServiceAreasTool, operation: 'update', id: service_area.slug, visible: true, confirm: true)

      expect(service_area.reload.visible).to be true
    end
  end

  describe 'operation=list' do
    it 'lists service areas' do
      service_area
      result = run(ServiceAreasTool, operation: 'list')

      expect(result['service_areas'].map { |a| a['name'] }).to include 'IA Aplicada'
    end

    it 'filters by visible' do
      service_area
      visible_area = FactoryBot.create(:service_area, name: 'Visible Area', visible: true)

      result = run(ServiceAreasTool, operation: 'list', visible: true)

      expect(result['service_areas'].map { |a| a['name'] }).to eq [visible_area.name]
    end
  end

  describe 'ServicesTool operation=update' do
    let(:service) { FactoryBot.create(:service, service_area: service_area, slug: 'consultoria-coaching-producto') }

    it 'warns when the slug changes that the old URL will redirect' do
      result = run(ServicesTool, operation: 'update', id: service.slug,
                                 slug: 'estrategia-descubrimiento-producto')

      expect(result['warnings']).to include(a_string_matching(/slug changes from "consultoria-coaching-producto".*301/))
    end

    it 'writes and reads back the hero image' do
      run(ServicesTool, operation: 'update', id: service.slug, confirm: true, hero_image: 'https://example.com/hero.webp')

      result = run(ServicesTool, operation: 'get', id: service.slug)

      expect(result['hero_image']).to eq 'https://example.com/hero.webp'
    end

    it 'writes and reads back the hero highlight' do
      run(ServicesTool, operation: 'update', id: service.slug, confirm: true,
                        hero_highlight: '3 meses', hero_highlight_text: 'con revisión cada 4 semanas')

      result = run(ServicesTool, operation: 'get', id: service.slug)

      expect(result).to include('hero_highlight' => '3 meses', 'hero_highlight_text' => 'con revisión cada 4 semanas')
    end

    describe 'redirect_url' do
      it 'warns that the page answers 301 and leaves the area page' do
        result = run(ServicesTool, operation: 'update', id: service.slug, redirect_url: '/es/servicios/otra/otro')

        expect(result['status']).to eq 'preview'
        expect(result['warnings'].join).to match(%r{301 to /es/servicios/otra/otro.*area page})
      end

      it 'saves it and reads it back' do
        run(ServicesTool, operation: 'update', id: service.slug, redirect_url: 'https://example.com/x', confirm: true)

        expect(run(ServicesTool, operation: 'get', id: service.slug)['redirect_url']).to eq 'https://example.com/x'
      end

      it 'rejects one that is neither a path nor a URL' do
        result = run(ServicesTool, operation: 'update', id: service.slug, redirect_url: 'servicios/otro',
                                   confirm: true)

        expect(result['status']).to eq 'error'
        expect(result['errors'].join).to include('Redirect url')
      end

      it 'takes it away with clear' do
        service.update!(redirect_url: '/es/otro')

        run(ServicesTool, operation: 'update', id: service.slug, clear: %w[redirect_url], confirm: true)

        expect(service.reload.redirect_url).to be_nil
      end

      it 'suggests one when the service is unpublished without it' do
        service.update!(published: true)

        result = run(ServicesTool, operation: 'update', id: service.slug, published: false)

        expect(result['warnings'].join).to include('redirect_url')
      end
    end

    # An empty string is not a value the tools accept, so emptying a field needs
    # its own argument (#217): a stale teaser and a placeholder FAQ had to be
    # removed from the admin.
    describe 'clear' do
      before do
        service.update!(card_description: 'Un teaser viejo', faq: '<ol><li>¿Algo?<ul><li>Sí</li></ul></li></ol>')
      end

      it 'previews emptying a field and a block without saving' do
        result = run(ServicesTool, operation: 'update', id: service.slug, clear: %w[card_description faq])

        expect(result['status']).to eq 'preview'
        expect(result['changes']['card_description']).to include('from_length' => 15, 'to_length' => 0)
        expect(result['changes']['faq']).to include('to_length' => 0)
        expect(service.reload.card_description).to eq 'Un teaser viejo'
      end

      it 'empties them on confirm' do
        run(ServicesTool, operation: 'update', id: service.slug, clear: %w[card_description faq], confirm: true)

        service.reload
        expect(service.card_description).to be_nil
        expect(service.faq.to_plain_text).to be_blank
      end

      it 'refuses a field the tool does not write, naming the ones it can empty' do
        result = run(ServicesTool, operation: 'update', id: service.slug, clear: %w[published], confirm: true)

        expect(result['status']).to eq 'error'
        expect(result['errors'].join).to include('published').and include('card_description')
      end

      it 'refuses a field that is also given a value' do
        result = run(ServicesTool, operation: 'update', id: service.slug, clear: %w[card_description],
                                   card_description: 'Otro', confirm: true)

        expect(result['status']).to eq 'error'
        expect(service.reload.card_description).to eq 'Un teaser viejo'
      end
    end

    # The site shows card_description only when it is HTML, an authored card
    # that replaces the generated one (#219); plain text is ignored.
    describe 'card_description' do
      it 'warns that plain text is not shown' do
        result = run(ServicesTool, operation: 'update', id: service.slug, card_description: 'Un teaser')

        expect(result['warnings'].join).to match(/card_description has no HTML.*ignores it/)
      end

      it 'takes an authored card without a warning' do
        result = run(ServicesTool, operation: 'update', id: service.slug,
                                   card_description: '<h2 class="rw-details-title">Frente 01</h2>')

        expect(result['warnings'].join).not_to include('card_description')
      end

      it 'says how the site uses it' do
        expect(ServicesTool.description).to include('generated card')
      end
    end

    # A FAQ with items the site misreads used to pass because it was not empty
    # (#218): the question in <strong> left ": Respuesta 1ra pregunta" as the
    # accordion title, with no answer under it.
    describe 'FAQ and program items the site shows broken' do
      it 'warns about a question the site cuts and an answer that is missing' do
        result = run(ServicesTool, operation: 'update', id: service.slug,
                                   faq: '<ol><li><strong>Primera pregunta</strong>: Respuesta 1ra pregunta</li></ol>')

        warnings = result['warnings'].join("\n")
        expect(warnings).to include('": Respuesta 1ra pregunta"')
        expect(warnings).to include('Primera pregunta: Respuesta 1ra pregunta')
        expect(warnings).to match(/faq item 1 has no answer/)
      end

      it 'says nothing about a FAQ the site reads whole' do
        result = run(ServicesTool, operation: 'update', id: service.slug,
                                   faq: '<ol><li>¿Cuánto dura?<ul><li>Tres meses</li></ul></li></ol>')

        expect(result['warnings'].join).not_to include('faq')
      end

      it 'takes a program step without detail as it is' do
        result = run(ServicesTool, operation: 'update', id: service.slug, program: '<ol><li>Diagnóstico</li></ol>')

        expect(result['warnings'].join).not_to include('program')
      end
    end
  end

  # Every tool that edits long text in place can also empty a field (#217).
  it 'offers clear wherever replacements is offered' do
    tools = ApplicationTool.descendants.select { |tool| tool.input_schema.key_map.map(&:name).include?('replacements') }

    expect(tools).not_to be_empty
    tools.each { |tool| expect(tool.input_schema.key_map.map(&:name)).to include('clear'), tool.name }
  end
end

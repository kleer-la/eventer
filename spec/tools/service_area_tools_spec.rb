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
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Service, type: :model do
  it 'trims slug before saving on create' do
    service = FactoryBot.build(:service, slug: '  test-slug  ')
    service.save
    expect(service.slug).to eq('test-slug')
  end
  it 'trims slug before saving on modify' do
    service = FactoryBot.create(:service)
    service.slug = '  test-slug  '
    service.save
    expect(service.slug).to eq('test-slug')
  end
  describe '#program_list' do
    it 'returns a list of strings with basic HTML styling' do
      service = Service.new
      service.program = ActionText::Content.new(
        '<ol><li>item title<ul><li>item <strong>content</strong></li></ul></li></ol>'
      )

      expect(service.program_list).to eq([['item title', 'item <strong>content</strong>']])
    end
  end
  describe '#recommended' do
    let(:service) { FactoryBot.create(:service) }
    let(:recommended_service) { FactoryBot.create(:service, name: 'Recomended', subtitle: 'For sure') }

    before do
      FactoryBot.create(:recommended_content, source: service, target: recommended_service, relevance_order: 2)
    end

    it 'returns recommended item with proper formatting' do
      recommended = service.recommended

      expect(recommended.size).to eq(1)
      expect(recommended.first['type']).to eq('service')

      expect(recommended.first['id']).to eq(recommended_service.id)
      expect(recommended.first['title']).to eq(recommended_service.name)
      expect(recommended.first['subtitle']).to eq(recommended_service.subtitle)
      expect(recommended.first['cover']).to eq(recommended_service.side_image)
    end
  end
  describe '#as_recommendation' do
    let(:service_area_es) { FactoryBot.create(:service_area, lang: 'es') }
    let(:service_area_en) { FactoryBot.create(:service_area, lang: 'en') }

    context 'when service has spanish service_area' do
      it 'uses service_area language regardless of passed lang parameter' do
        service = FactoryBot.create(:service,
                                    service_area: service_area_es,
                                    name: 'Test Service',
                                    subtitle: '<h1>Test Subtitle</h1>')

        result = service.as_recommendation(lang: 'en')

        expect(result['lang']).to eq('es')
        expect(result['title']).to eq('Test Service')
        expect(result['subtitle']).to eq('Test Subtitle')
        expect(result['cover']).to eq(service.side_image)
      end

      it 'still returns spanish when lang parameter matches' do
        service = FactoryBot.create(:service,
                                    service_area: service_area_es,
                                    name: 'Spanish Service',
                                    subtitle: 'Spanish Subtitle')

        result = service.as_recommendation(lang: 'es')

        expect(result['lang']).to eq('es')
        expect(result['title']).to eq('Spanish Service')
        expect(result['subtitle']).to eq('Spanish Subtitle')
      end
    end

    context 'when service has english service_area' do
      it 'uses english service_area language regardless of passed lang parameter' do
        service = FactoryBot.create(:service,
                                    service_area: service_area_en,
                                    name: 'English Service',
                                    subtitle: 'English Subtitle')

        result = service.as_recommendation(lang: 'es')

        expect(result['lang']).to eq('en')
        expect(result['title']).to eq('English Service')
        expect(result['subtitle']).to eq('English Subtitle')
      end
    end

    context 'when no lang parameter is provided' do
      it 'uses service_area language and ignores default parameter' do
        service = FactoryBot.create(:service,
                                    service_area: service_area_en,
                                    name: 'Default Test Service',
                                    subtitle: 'Default Test Subtitle')

        result = service.as_recommendation

        expect(result['lang']).to eq('en')
        expect(result['title']).to eq('Default Test Service')
        expect(result['subtitle']).to eq('Default Test Subtitle')
      end
    end

    context 'subtitle HTML cleaning' do
      it 'removes h1 tags from subtitle' do
        service = FactoryBot.create(:service,
                                    service_area: service_area_es,
                                    subtitle: '<h1>Title with H1</h1>')

        result = service.as_recommendation

        expect(result['subtitle']).to eq('Title with H1')
      end

      it 'handles multiple h1 tags' do
        service = FactoryBot.create(:service,
                                    service_area: service_area_es,
                                    subtitle: '<h1>First</h1> and <h1>Second</h1>')

        result = service.as_recommendation

        expect(result['subtitle']).to eq('First and Second')
      end

      it 'leaves other HTML tags intact' do
        service = FactoryBot.create(:service,
                                    service_area: service_area_es,
                                    subtitle: '<h1>Title</h1> with <strong>bold</strong> text')

        result = service.as_recommendation

        expect(result['subtitle']).to eq('Title with <strong>bold</strong> text')
      end
    end

    context 'integration with parent class' do
      it 'includes fields from parent as_recommendation method' do
        service = FactoryBot.create(:service, service_area: service_area_es)

        result = service.as_recommendation

        # These should come from the parent class (Recommendable module)
        expect(result).to have_key('type')
        expect(result).to have_key('id')

        # These are added by the Service override
        expect(result).to have_key('title')
        expect(result).to have_key('subtitle')
        expect(result).to have_key('cover')
        expect(result).to have_key('lang')
      end
    end
  end
end

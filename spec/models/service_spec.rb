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
      expect(recommended.first['description']).to eq(recommended_service.subtitle)
    end
  end
end

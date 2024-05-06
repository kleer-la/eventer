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
end

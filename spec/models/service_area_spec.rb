# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ServiceArea, type: :model do
  it 'trims slug before saving on create' do
    service_area = FactoryBot.build(:service_area, slug: '  test-slug  ')
    service_area.save
    expect(service_area.slug).to eq('test-slug')
  end
  it 'trims slug before saving on modify' do
    service_area = FactoryBot.create(:service_area)
    service_area.slug = '  test-slug  '
    service_area.save
    expect(service_area.slug).to eq('test-slug')
  end
end

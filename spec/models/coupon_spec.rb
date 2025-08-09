# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Coupon, type: :model do
  it 'is valid with valid attributes and no specific off amounts' do
    coupon = FactoryBot.build(:coupon, :codeless)
    expect(coupon).to be_valid
  end

  it 'creates a valid percent_off coupon' do
    coupon = FactoryBot.build(:coupon, :percent_off)
    expect(coupon.coupon_type).to eq('percent_off')
    expect(coupon.percent_off).to be_present
    expect(coupon).to be_valid
  end

  it 'creates a valid amount_off coupon' do
    coupon = FactoryBot.build(:coupon, :amount_off)
    expect(coupon.coupon_type).to eq('amount_off')
    expect(coupon.amount_off).to be_present
    expect(coupon).to be_valid
  end

  it 'has a valid many-to-many relation with EventTypes' do
    event_type = FactoryBot.create(:event_type)
    coupon = FactoryBot.create(:coupon)
    coupon.event_types << event_type
    expect(coupon.event_types).to include(event_type)
  end

  it 'Normalize code' do
    coupon = FactoryBot.create(:coupon, code: ' abacaxi ')
    expect(coupon.code).to eq 'ABACAXI'
  end

  describe 'ImageReference behavior' do
    let(:icon_url) { 'https://kleer-images.s3.sa-east-1.amazonaws.com/coupon-icon.png' }

    describe '#image_references' do
      let(:coupon) { create(:coupon, icon: icon_url) }

      it 'finds direct references in icon field' do
        references = coupon.image_references(icon_url)
        expect(references).to include(
          hash_including(
            field: :icon,
            type: 'direct'
          )
        )
      end

      it 'returns empty array when URL not found' do
        references = coupon.image_references('https://not-found.com/missing.png')
        expect(references).to be_empty
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Coupon, type: :model do
  it 'is valid with valid attributes and no specific off amounts' do
    coupon = FactoryBot.build(:coupon, :couponless)
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
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParticipantsHelper, type: :helper do
  it 'Manage currency' do
    @event = FactoryBot.build(:event, currency_iso_code: 'USD')
    expect(quantity_list[0][0]).to include 'USD'
  end
  it 'Number <1000 w/o decimals' do
    @event = FactoryBot.build(:event, currency_iso_code: 'USD')
    expect(quantity_list[0][0]).to include ' 500 '
    expect(quantity_list[0][0]).not_to include '.0'
  end
  it 'Number >1000 w/ thousand separator' do
    @event = FactoryBot.build(:event, list_price: 1_234_567)
    expect(quantity_list[0][0]).to include ' 1.234.567 '
  end
  it 'Coupons with code dont change the showed price' do
    @event = FactoryBot.build(:event, list_price: 12_345)
    FactoryBot.create(:coupon, :percent_off, percent_off: 50.0, code: 'ABRADADABRA')
              .event_types << @event.event_type
    expect(quantity_list[0][0]).to include ' 12.345 '
  end
end

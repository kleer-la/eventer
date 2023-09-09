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
    @event = FactoryBot.build(:event, list_price: 1234567)
    expect(quantity_list[0][0]).to include ' 1.234.567 '
  end
end

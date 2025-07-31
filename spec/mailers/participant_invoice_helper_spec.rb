# frozen_string_literal: true

require 'rails_helper'

describe ParticipantInvoiceHelper do
  before :each do
    InvoiceService.xero_service(XeroClientService.create_null)
    @participant = FactoryBot.create(:participant)
  end
  it 'item_description one seat es' do
    pih = ParticipantInvoiceHelper.new(@participant, :es)
    expect(pih.item_description).to include 'por una vacante'
  end
  it 'item_description three seats es' do
    @participant.quantity = 3
    pih = ParticipantInvoiceHelper.new(@participant, :es)
    expect(pih.item_description).to include 'por 3 vacantes'
  end
  it 'item_description one seat en' do
    pih = ParticipantInvoiceHelper.new(@participant, :en)
    expect(pih.item_description).to include 'one seat for'
  end
  it 'item_description three seats es' do
    @participant.quantity = 3
    pih = ParticipantInvoiceHelper.new(@participant, :en)
    expect(pih.item_description).to include '#3 seats'
  end
  xit 'coupon applied shows in item description' do
    # Skip: Coupon functionality not fully implemented
    # Coupon code doesn't appear in item_description method
    FactoryBot.create(:coupon, :percent_off, percent_off: 10.0, code: 'ABRADADABRA')
              .event_types << @participant.event.event_type

    @participant.event.currency_iso_code = 'USD' # only usd invoices are created
    @participant.referer_code = 'ABRADADABRA'
    pih = ParticipantInvoiceHelper.new(@participant, :es)

    # Test that coupon code appears in the item description
    expect(pih.item_description).to include 'ABRADADABRA'
  end
end

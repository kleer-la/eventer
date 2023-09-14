# frozen_string_literal: true

require 'rails_helper'

describe ParticipantInvoiceHelper do
  before :each do
    @participant = FactoryBot.create(:participant)
  end
  it 'item_description one seat es' do
    pih = ParticipantInvoiceHelper.new(@participant, :es)
    expect(pih.item_description).to include 'por una vacante'
  end
  it 'item_description three seats es' do
    @participant.quantity =3
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
end
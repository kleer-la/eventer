# frozen_string_literal: true

require 'rails_helper'

describe InvoiceService do
  before :each do
    InvoiceService.xero_service(XeroClientService.create_null)
    @participant = FactoryBot.create(:participant)
    @service = InvoiceService.new(@participant)
  end

  it 'Invoice in COP is not possible!' do
    @participant.event.currency_iso_code = 'COP'

    expect(@service.create_send_invoice).to be_nil
  end
  it 'Invoice in USD is possible!' do
    @participant.event.currency_iso_code = 'USD'

    expect(@service.create_send_invoice).not_to be_nil
  end

  context 'Create Invoice' do
    before :each do
      @participant.event.date = DateTime.new(2022, 1, 20)
      @participant.event.eb_end_date = DateTime.new(2022, 1, 10)
    end
    it 'normal due date' do
      due_date = InvoiceService.due_date(@participant.event, DateTime.new(2022, 1, 1))
      expect(due_date.to_date.to_s).to eq '2022-01-08'
    end
    it 'normal due date > eb' do
      due_date = InvoiceService.due_date(@participant.event, DateTime.new(2022, 1, 4))
      expect(due_date.to_date.to_s).to eq '2022-01-10'
    end
    it 'normal due date > curse date' do
      due_date = InvoiceService.due_date(@participant.event, DateTime.new(2022, 1, 14))
      expect(due_date.to_date.to_s).to eq '2022-01-19'
    end
    it 'no eb' do
      @participant.event.eb_end_date = nil
      due_date = InvoiceService.due_date(@participant.event, DateTime.new(2022, 1, 4))
      expect(due_date.to_date.to_s).to eq '2022-01-11'
    end
    it 'today > eb' do
      due_date = InvoiceService.due_date(@participant.event, DateTime.new(2022, 1, 11))
      expect(due_date.to_date.to_s).to eq '2022-01-18'
    end
  end

end

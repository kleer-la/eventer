# frozen_string_literal: true

require 'rails_helper'

describe XeroClientService do
  it 'Create Contact has no error' do
    xero = XeroClientService::XeroApi.new(XeroClientService.create_null)

    response = xero.create_contact('Contact Name', 'Contact', 'Name', 'e@mail.com', '543-2109', '1st street')

    expect(response.has_validation_errors).to be false
  end
  it 'Create Invoice with API error' do
    xero = XeroClientService::XeroApi.new(
            XeroClientService.create_null(
              invoice_exception: XeroRuby::ApiError.new('Invoice error')
            )
          )

    expect {
      response = xero.create_invoices('Contact id', 'Description', 1, 1.23, '2022-07-20', '2022-07-30','CODE', :es)
    }.to change {Log.count}.by 1
  end
  it 'Send Invoice with API error' do
    xero = XeroClientService::XeroApi.new(
            XeroClientService.create_null(
              email_exception: XeroRuby::ApiError.new('Send Invoice error')
            )
          )
    invoice = xero.create_invoices('Contact id', 'Description', 1, 1.23, '2022-07-20', '2022-07-30','CODE', :es)
    expect {
      response = xero.email_invoice(invoice)
    }.to change {Log.count}.by 1
  end
  it 'get online link' do
    xero = XeroClientService::XeroApi.new(
      XeroClientService.create_null
    )
    invoice = xero.create_invoices('Contact id', 'Description', 1, 1.23, '2022-07-20', '2022-07-30','CODE', :es)
    expect(xero.get_online_invoice_url(invoice)).to eq 'https://in.xero.com/ZBu1Js9EHEdeR2A0LAeaL6NqYIytXgjOzRIBOoW9'
  end
  describe XeroClientService::TrackingCategories do
    # to try on dev environment
    # rails c
    # tracking_categories = XeroClientService::TrackingCategories.new(XeroClientService.create_xero
    it 'validate_or_create doesnt raise error' do
      tracking_categories = XeroClientService::TrackingCategories.new(
        XeroClientService.create_null
      )
      expect {tracking_categories.validate_or_create('_CLEARING_CO')}.not_to raise_error
    end
    it 'valid? yeap / nop' do
      tracking_categories = XeroClientService::TrackingCategories.new(
        XeroClientService.create_null
      )
      expect(tracking_categories.valid?('_CLEARING_CO')).to be true
      expect(tracking_categories.valid?('_CLEARING_C')).to be false
    end
  end
  describe 'get tenant_id' do
    it 'null xero' do
      xero = XeroClientService::XeroApi.new(XeroClientService.create_null(tenant_id: 'pepe'))  
      expect(xero.tenant_id).to eq 'pepe'
      end
  end
end

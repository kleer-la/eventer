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
      response = xero.create_invoices('Contact id', 'Description', 1, 1.23, '2022-07-20', '2022-07-30','CODE')
    }.to change {Log.count}.by 1
  end
  it 'Send Invoice with API error' do
    xero = XeroClientService::XeroApi.new(
            XeroClientService.create_null(
              email_exception: XeroRuby::ApiError.new('Send Invoice error')
            )
          )
    invoice = xero.create_invoices('Contact id', 'Description', 1, 1.23, '2022-07-20', '2022-07-30','CODE')
    expect {
      response = xero.email_invoice(invoice)
    }.to change {Log.count}.by 1
  end
  it 'get online link' do
    xero = XeroClientService::XeroApi.new(
      XeroClientService.create_null
    )
    invoice = xero.create_invoices('Contact id', 'Description', 1, 1.23, '2022-07-20', '2022-07-30','CODE')
    expect(xero.get_online_invoice_url(invoice)).to eq 'https://in.xero.com/ZBu1Js9EHEdeR2A0LAeaL6NqYIytXgjOzRIBOoW9'
  end
end

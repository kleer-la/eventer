# frozen_string_literal: true

require 'rails_helper'

describe XeroClientService do
  it 'Create Contact has no error' do
    xero = XeroClientService::XeroApi.new(XeroClientService.create_null)

    response = xero.create_contact('Contact Name', 'Contact', 'Name', 'e@mail.com', '543-2109', '1st street')

    expect(response.has_validation_errors).to be false
  end
end

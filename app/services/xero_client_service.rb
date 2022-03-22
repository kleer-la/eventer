# frozen_string_literal: true

require 'xero-ruby'

module XeroClientService
  def self.build_client
    raise 'You must specify the XERO_CLIENT_ID env variable' unless xero_client_id = ENV['XERO_CLIENT_ID']
    raise 'You must specify the XERO_CLIENT_SECRET env variable' unless xero_client_secret = ENV['XERO_CLIENT_SECRET']
    raise 'You must specify the XERO_REDIRECT_URI env variable' unless xero_redirect_uri = ENV['XERO_REDIRECT_URI']
    raise 'You must specify the XERO_SCOPES env variable' unless xero_scopes = ENV['XERO_SCOPES']

    creds = {
      client_id: xero_client_id,
      client_secret: xero_client_secret,
      redirect_uri: xero_redirect_uri,
      scopes: xero_scopes
    }
    config = {
      # timeout: 30,
      # debugging: Rails.env.development?
    }
    xero_client ||= XeroRuby::ApiClient.new(credentials: creds, config: config)
  end

  def self.initialized_client
    oauth_token = OauthToken.first

    xero_client = build_client
    xero_client.set_token_set(oauth_token.token_set)

    if oauth_token.about_to_expire?
      puts 'Refrescando token'
      # este método almacena en el cliente el nuevo token
      new_token_set = xero_client.refresh_token_set(oauth_token.token_set)
      unless new_token_set['error']
        oauth_token.token_set = new_token_set
        # Por el momento desactivo esta actualización para prevenir un problema
        # detectado (y aparentemente resuelto) en xero-ruby en versiones previas
        # a la 2.9.1
        # oauth_token.tenant_id = xero_client.connections.last['tenantId']
        oauth_token.save!
        puts 'Token refrescado'
      end
    end

    [xero_client, oauth_token.tenant_id]
  end

  class XeroApi
    def initialize(client)
      @client = client
    end

    def create_contact(name, fname, lname, email, phone, address)
      summarize_errors = true

      phones = [{
        phone_number: phone,
        phone_type: XeroRuby::Accounting::Phone::MOBILE
      }]

      addresses = [{
        address_line_1: address,
        address_type: XeroRuby::Accounting::Address::STREET
      }]

      payment_terms = {
        sales: { day: 7, type: XeroRuby::Accounting::PaymentTermType::DAYSAFTERBILLDATE }
      }
      # "PaymentTerms": {
      #   "Sales": {
      #     "Day": 7,
      #     "Type": "DAYSAFTERBILLDATE"
      #   }

      contacts = { contacts: [{
        name: name,
        first_name: fname,
        last_name: lname,
        email_address: email,
        addresses: addresses,
        phones: phones,
        payment_terms: payment_terms
      }] }

      begin
        @client.create_contacts(contacts, summarize_errors: summarize_errors)
      rescue XeroRuby::ApiError => e
        puts "Exception when calling create_contacts: #{e}"
        @client.get_contacts({ search_term: name })
      end
    end

    SERVICE_ACCOUNT = '4300'
    def create_invoices(contact_id, description, quantity, unit, date, due_date, codename)
      branding_theme = { branding_theme_id: 'fc426c1a-bbd1-4725-a973-3ead6fde8a60' } # , name: 'Curso'
      # "BrandingTheme": {
      #   "BrandingThemeID": "fc426c1a-bbd1-4725-a973-3ead6fde8a60",
      #   "Name": "Curso"
      # },

      invoice_data = { invoices: [{ type: XeroRuby::Accounting::Invoice::ACCREC,
                                    contact: { contact_id: contact_id },
                                    line_items: [{ description: description, quantity: quantity, unit_amount: unit,
                                                   account_code: SERVICE_ACCOUNT, tax_type: XeroRuby::Accounting::TaxType::NONE }],
                                    date: date, due_date: due_date, reference: codename,
                                    branding_theme: branding_theme,
                                    status: XeroRuby::Accounting::Invoice::DRAFT }] }
      begin
        @client.create_invoices(invoice_data)
      rescue XeroRuby::ApiError => e
        puts "Exception when calling create_invoices: #{e}"
      end
    end
  end

  def self.create_null(...)
    NullXero.new(...)
  end

  def self.create_xero
    Xero.new
  end

  class NullXero
    def initialize(has_validation_error: false)
      @has_validation_error = has_validation_error
    end

    def create_contacts(...)
      NullResponse.new(has_validation_errors: @has_validation_error)
    end

    def create_invoices(...)
      NullResponse.new(has_validation_errors: @has_validation_error)
    end
  end

  # { "Id": "e997d6d7-6dad-4458-beb8-d9c1bf7f2edf", "Status": "OK", "ProviderName": "Xero API Partner",
  #   "DateTimeUTC": "/Date(1551399321121)/", "Contacts": [ { "ContactID": "3ff6d40c-af9a-40a3-89ce-3c1556a25591",
  #     "ContactStatus": "ACTIVE", "Name": "Foo9987", "EmailAddress": "sid32476@blah.com", "BankAccountDetails": "",
  #     "Addresses": [ { "AddressType": "STREET", "City": "", "Region": "", "PostalCode": "", "Country": "" },
  #       { "AddressType": "POBOX", "City": "", "Region": "", "PostalCode": "", "Country": "" } ], "Phones": [ { "PhoneType": "DEFAULT", "PhoneNumber": "", "PhoneAreaCode": "", "PhoneCountryCode": "" },
  #       { "PhoneType": "DDI", "PhoneNumber": "", "PhoneAreaCode": "", "PhoneCountryCode": "" },
  #       { "PhoneType": "FAX", "PhoneNumber": "", "PhoneAreaCode": "", "PhoneCountryCode": "" },
  #       { "PhoneType": "MOBILE", "PhoneNumber": "555-1212", "PhoneAreaCode": "415", "PhoneCountryCode": "" } ],
  #       "UpdatedDateUTC": "/Date(1551399321043+0000)/", "ContactGroups": [], "IsSupplier": false, "IsCustomer": false,
  #       "SalesTrackingCategories": [], "PurchasesTrackingCategories": [],
  #       "PaymentTerms": { "Bills": { "Day": 15, "Type": "OFCURRENTMONTH" },
  #       "Sales": { "Day": 10, "Type": "DAYSAFTERBILLMONTH" } }, "ContactPersons": [], "HasValidationErrors": false } ] }

  class NullResponse
    attr_reader :has_validation_errors

    def initialize(has_validation_errors: false)
      @has_validation_errors = has_validation_errors
    end

    def contacts
      [NullContact.new]
    end

    def invoices
      [NullInvoice.new]
    end
  end

  class NullContact
    attr_reader :contact_id

    def initialize
      @contact_id = '1234567890abcdefg'
    end
  end

  class NullInvoice
    attr_reader :invoice_number

    def initialize
      @invoice_number = 'INV-0100'
    end
  end

  class Xero
    def initialize
      @xero_client,
      @xero_tenant_id = XeroClientService.initialized_client
    end

    def create_contacts(...)
      @xero_client.accounting_api.create_contacts(@xero_tenant_id, ...)
    end

    def get_contacts(...)
      @xero_client.accounting_api.get_contacts(@xero_tenant_id, ...)
    end

    def create_invoices(...)
      @xero_client.accounting_api.create_invoices(@xero_tenant_id, ...).invoices.first
    end
  end
end

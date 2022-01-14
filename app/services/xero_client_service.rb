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

  def self.create_contact(name, fname, lname, email, phone, address)
    # xero_client.set_token_set(user.token_set)
    # xero_tenant_id = 'YOUR_XERO_TENANT_ID'
    xero_client, 
    xero_tenant_id = initialized_client
    summarize_errors = true

    phones = [{ 
      phone_number: phone,
      phone_type:  XeroRuby::Accounting::Phone::MOBILE
    }]

    addresses = [{
      address_line_1: address,
      address_type: XeroRuby::Accounting::Address::STREET
    }]
    
    payment_terms= {
      sales: {day: 7, type: XeroRuby::Accounting::PaymentTermType::DAYSAFTERBILLDATE}
    }
    # "PaymentTerms": {
    #   "Sales": {
    #     "Day": 7,
    #     "Type": "DAYSAFTERBILLDATE"
    #   }

    branding_theme= {branding_theme_id: 'fc426c1a-bbd1-4725-a973-3ead6fde8a60', name: 'Curso'}
    # "BrandingTheme": {
    #   "BrandingThemeID": "fc426c1a-bbd1-4725-a973-3ead6fde8a60",
    #   "Name": "Curso"
    # },


    contacts = {contacts: [{ 
      name: name,
      first_name: fname,
      last_name: lname,
      email_address: email,
      addresses: addresses,
      phones: phones,
      payment_terms: payment_terms,
      branding_theme: branding_theme
    }]}

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

    begin
      response = xero_client.accounting_api.create_contacts(xero_tenant_id, contacts, summarize_errors: summarize_errors )
      return response
    rescue XeroRuby::ApiError => e
      puts "Exception when calling create_contacts: #{e}"
    end
  end
  
end

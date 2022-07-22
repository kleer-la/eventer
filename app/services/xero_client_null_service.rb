module XeroClientService
  class NullXero
    def initialize(has_validation_error: false, invoice_exception: nil, email_exception: nil)
      @has_validation_error = has_validation_error
      @invoice_exception = invoice_exception
      @email_exception = email_exception
    end

    def create_contacts(...)
      NullResponse.new(has_validation_errors: @has_validation_error)
    end

    def create_invoices(...)
      raise @invoice_exception if @invoice_exception
      NullInvoice.new()
    end
    
    def email_invoice(invoice)
      raise @email_exception if @email_exception
    end
  end

  # { "Id": "e997d6d7-6dad-4458-beb8-d9c1bf7f2edf", "Status": "OK", "ProviderName": "Xero API Partner",
  #   "DateTimeUTC": "/Date(1551399321121)/", "Contacts": [ { "ContactID": "3ff6d40c-af9a-40a3-89ce-3c1556a25591",
  #     "ContactStatus": "ACTIVE", "Name": "Foo9987", "EmailAddress": "sid32476@blah.com", "BankAccountDetails": "",
  #     "Addresses": [ { "AddressType": "STREET", "City": "", "Region": "", "PostalCode": "", "Country": "" },
  #       { "AddressType": "POBOX", "City": "", "Region": "", "PostalCode": "", "Country": "" } ],
  #         "Phones": [ { "PhoneType": "DEFAULT", "PhoneNumber": "", "PhoneAreaCode": "", "PhoneCountryCode": "" },
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
  end

  class NullContact
    attr_reader :contact_id

    def initialize
      @contact_id = '1234567890abcdefg'
    end
  end

  class NullInvoice
    attr_reader :invoice_number, :invoice_id

    def initialize
      @invoice_number = 'INV-0100'
      @invoice_id = 'a12346' * 6 # 36 char
    end
  end
end
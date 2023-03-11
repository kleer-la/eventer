module XeroClientService
  class NullXero
    attr_reader :tenant_id

    def initialize(has_validation_error: false, invoice_exception: nil, 
      email_exception: nil, tenant_id: nil)
      @has_validation_error = has_validation_error
      @invoice_exception = invoice_exception
      @email_exception = email_exception
      @tenant_id = tenant_id
    end

    def create_tracking_options(...)
    end

    def get_tracking_category(...)
      NullResponse.new(has_validation_errors: @has_validation_error)            
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

    def get_online_invoice(_)
      NullOnlineInvoices.new
    end
    def get_invoice(_)
      NullInvoice.new
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
    def tracking_categories
      [NullTrackingCategory.new]
    end    
  end

  class NullContact
    attr_reader :contact_id

    def initialize
      @contact_id = '1234567890abcdefg'
    end
  end

  class NullTrackingCategory
    def options
      [NullTrackingCategoryOption.new]
    end
# {
#   "Id": "209b745b-da27-4f23-8f5d-a4ae952bb7a6",
#   "Status": "OK",
#   "ProviderName": "API Explorer",
#   "DateTimeUTC": "\/Date(1666454143574)\/",
#   "TrackingCategories": [
#     {
#       "Name": "Cód. Proyecto",
#       "Status": "ACTIVE",
#       "TrackingCategoryID": "63a79b77-227b-4144-9be8-06e7a839d946",
#       "Options": [
#         {
#           "TrackingOptionID": "99b4b914-5aa2-4610-bd48-e5494734251f",
#           "Name": "_CLEARING_CO",
#           "Status": "ACTIVE",
#           "HasValidationErrors": false,
#           "IsDeleted": false,
#           "IsArchived": false,
#           "IsActive": true
#         },
#         {
#           "TrackingOptionID": "91a499c4-4c22-4976-b1ad-c0fddaa94404",
#           "Name": "_CLEARING_UY",
#           "Status": "ACTIVE",
#           "HasValidationErrors": false,
#           "IsDeleted": false,
#           "IsArchived": false,
#           "IsActive": true
#         },
#       }
#   ]
# }    
  end
  class NullTrackingCategoryOption
    attr_reader :name

    def initialize(name = '_CLEARING_CO')
      @name = name
    end
    #     "TrackingOptionID": "99b4b914-5aa2-4610-bd48-e5494734251f",
    #     "Name": "_CLEARING_CO",
    #     "Status": "ACTIVE",
    #     "HasValidationErrors": false,
    #     "IsDeleted": false,
    #     "IsArchived": false,
    #     "IsActive": true
  end
 
  class NullInvoice
    attr_reader :invoice_number, :invoice_id, :amount_paid
    def initialize
      @invoice_number = 'INV-0100'
      @invoice_id = 'a12346' * 6 # 36 char
      @amount_paid = 720.0
    end
  end

  class NullOnlineInvoices 
    attr_reader :online_invoices
    def initialize
      @online_invoices = [NullOnlineInvoice.new]
    end
    class NullOnlineInvoice
      attr_reader :online_invoice_url
      def initialize
        @online_invoice_url = 'https://in.xero.com/ZBu1Js9EHEdeR2A0LAeaL6NqYIytXgjOzRIBOoW9'
      end
    end
  end
end
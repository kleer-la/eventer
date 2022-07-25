# frozen_string_literal: true

require 'xero-ruby'
require 'xero_client_null_service'

# https://github.com/XeroAPI/xero-ruby/blob/master/lib/xero-ruby/api/accounting_api.rb

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

    BRANDING_THEME = {
      es: 'fc426c1a-bbd1-4725-a973-3ead6fde8a60',
      en: '0420bcfb-62ef-428a-a178-b02ff936ed3d'  }

    SERVICE_ACCOUNT = '4300'
    def create_invoices(contact_id, description, quantity, unit, date, due_date, codename, lang)
      invoice_data = { invoices: [{ type: XeroRuby::Accounting::Invoice::ACCREC,
                                    contact: { contact_id: contact_id },
                                    line_items: [{ description: description, quantity: quantity, unit_amount: unit,
                                                   account_code: SERVICE_ACCOUNT, tax_type: XeroRuby::Accounting::TaxType::NONE,
                                                   tracking: [{ name: 'Cód. Proyecto', option: codename }] }],
                                    date: date, due_date: due_date, reference: codename,
                                    branding_theme_id: BRANDING_THEME[lang.to_sym],
                                    status: XeroRuby::Accounting::Invoice::AUTHORISED }] } # DRAFT / AUTHORISED
      begin
        @client.create_invoices(invoice_data)
        # <XeroRuby::Accounting::Invoice:0x00007fd0082d7960
        #   @has_attachments=false,
        #   @has_errors=false, @type="ACCREC",
        #   @contact=#<XeroRuby::Accounting::Contact:0x00007fd0082d7500
        #     @has_attachments=false, @has_validation_errors=false, @contact_id="55862b5e-1707-4299-9d75-f01068d285fb", @contact_status="ACTIVE",
        #     @name="Prueba prueba", @first_name="Prueba", @last_name="prueba", @email_address="juliana541@gmail.com", @contact_persons=[],
        #     @bank_account_details="", @addresses=[#<XeroRuby::Accounting::Address:0x00007fd0082d6ab0 @address_type="STREET", @address_line1="prueba",
        #     @city="", @region="", @postal_code="", @country="">, #<XeroRuby::Accounting::Address:0x00007fd0082d63f8 @address_type="POBOX", @city="",
        #     @region="", @postal_code="", @country="">], @phones=[#<XeroRuby::Accounting::Phone:0x00007fd0082d5cf0 @phone_type="DEFAULT", @phone_number="",
        #     @phone_area_code="", @phone_country_code="">, #<XeroRuby::Accounting::Phone:0x00007fd0082d5778 @phone_type="DDI", @phone_number="",
        #     @phone_area_code="", @phone_country_code="">, #<XeroRuby::Accounting::Phone:0x00007fd0082d5228 @phone_type="FAX", @phone_number="",
        #     @phone_area_code="", @phone_country_code="">, #<XeroRuby::Accounting::Phone:0x00007fd0082d4c60 @phone_type="MOBILE", @phone_number="1111111",
        #     @phone_area_code="", @phone_country_code="">], @is_supplier=false, @is_customer=true,
        #     @payment_terms=#<XeroRuby::Accounting::PaymentTerm:0x00007fd0082d4198 @sales=#<XeroRuby::Accounting::Bill:0x00007fd0082cffa8
        #       @day=7, @type="DAYSAFTERBILLDATE">>, @updated_date_utc=Tue, 22 Feb 2022 17:21:43 +0000, @contact_groups=[], @sales_tracking_categories=[],
        #       @purchases_tracking_categories=[]>,
        #   @line_items=[#<XeroRuby::Accounting::LineItem:0x00007fd0082cf148 @line_item_id="2a09ce4d-ad2a-4231-89fd-a48ac85e9405",
        #     @description="Tipo de Evento de Prueba -  OnLine  - 10 Jun -\n por 2 vacantes", @quantity=0.2e1, @unit_amount=0.9e2,
        #     @account_code="4300", @tax_type="NONE", @tax_amount=0.0, @line_amount=0.18e3, @tracking=[]>],
        #   @date=Thu, 24 Mar 2022, @due_date=Thu, 31 Mar 2022, @line_amount_types="Exclusive", @invoice_number="INV-0363", @reference="",
        #   @branding_theme_id="fc426c1a-bbd1-4725-a973-3ead6fde8a60", @currency_code="USD", @currency_rate=0.1e1, @status="DRAFT", @sent_to_contact=false,
        #   @sub_total=0.18e3, @total_tax=0.0, @total=0.18e3, @invoice_id="50f0d30c-5791-48cd-9357-cdcf8a001e29", @is_discounted=false,
        #   @prepayments=[], @overpayments=[], @amount_due=0.18e3, @amount_paid=0.0, @updated_date_utc=Thu, 24 Mar 2022 18:24:08 +0000>
        #
      rescue XeroRuby::ApiError => e
        Log.log(:xero, :error,  
          "contact:#{contact_id}", 
          e.message + ' - ' + e.backtrace.grep_v(%r{/gems/}).join('\n')
         )
         nil
      end
    end

    def email_invoice(invoice)
      begin
        @client.email_invoice(invoice.invoice_id)
      rescue StandardError => e 
       Log.log(:xero, :warn,
         "invoice not sent :#{invoice.invoice_number}", 
         e.message + ' - ' + e.backtrace.grep_v(%r{/gems/}).join('\n')
        )
      end
    end
    
    def get_online_invoice_url(invoice)
      return nil if invoice.nil?

      data = @client.get_online_invoice(invoice.invoice_id)
      data.online_invoices[0].online_invoice_url
    end
  end

  def self.create_null(...)
    NullXero.new(...)
  end

  def self.create_xero
    Xero.new
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

    def email_invoice(invoice_id, request_empty = [], opts = {})
      @xero_client.accounting_api.email_invoice(@xero_tenant_id, invoice_id, request_empty, opts)
    end
    # GET https://api.xero.com/api.xro/2.0/Invoices/9b9ba9e5-e907-4b4e-8210-54d82b0aa479/OnlineInvoice
    # {
    #   "OnlineInvoices": [
    #     {
    #       "OnlineInvoiceUrl": "https://in.xero.com/iztKMjyAEJT7MVnmruxgCdIJUDStfRgmtdQSIW13"
    #     }
    #   ]
    # }
    def get_online_invoice(invoice_id)
      data = @xero_client.accounting_api.get_online_invoice(@xero_tenant_id, invoice_id)
    end
  end
end

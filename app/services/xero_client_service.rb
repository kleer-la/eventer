# frozen_string_literal: true

require 'xero-ruby'

# https://github.com/XeroAPI/xero-ruby/blob/master/lib/xero-ruby/api/accounting_api.rb

module XeroClientService
  class << self
    attr_accessor :xero_client
  end

  def self.build_client
    return @xero_client if @xero_client

    xero_client_id = ENV.fetch('XERO_CLIENT_ID') { raise 'You must specify the XERO_CLIENT_ID env variable' }
    xero_client_secret = ENV.fetch('XERO_CLIENT_SECRET') do
      raise 'You must specify the XERO_CLIENT_SECRET env variable'
    end
    xero_redirect_uri = ENV.fetch('XERO_REDIRECT_URI') { raise 'You must specify the XERO_REDIRECT_URI env variable' }
    xero_scopes = ENV.fetch('XERO_SCOPES') { raise 'You must specify the XERO_SCOPES env variable' }
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
    @xero_client = XeroRuby::ApiClient.new(credentials: creds, config:)
  end

  def self.initialized_client
    oauth_token = OauthToken.first
    if oauth_token.nil?
      Log.log(:xero, :error, 'oauth_token nil', caller.to_s)
      return
    end

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

    def tenant_id
      @client.tenant_id
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
        name:,
        first_name: fname,
        last_name: lname,
        email_address: email,
        addresses:,
        phones:,
        payment_terms:
      }] }

      begin
        @client.create_contacts(contacts, summarize_errors:)
      rescue XeroRuby::ApiError => e
        Log.log(:xero, :warn,
                "Exception when calling create_contacts:#{contacts}",
                "#{e.message} - #{e.backtrace.grep_v(%r{/gems/}).join('\n')}")

        @client.get_contacts({ search_term: name })
      end
    end

    BRANDING_THEME = {
      es: 'fc426c1a-bbd1-4725-a973-3ead6fde8a60',
      en: '0420bcfb-62ef-428a-a178-b02ff936ed3d'
    }.freeze

    SERVICE_ACCOUNT = '4300'
    def create_invoices(contact_id, description, quantity, unit, date, due_date, codename, lang)
      TrackingCategories.new(@client).validate_or_create(codename)

      invoice_data = { invoices: [{ type: XeroRuby::Accounting::Invoice::ACCREC,
                                    contact: { contact_id: },
                                    line_items: [{ description:, quantity:, unit_amount: unit,
                                                   account_code: SERVICE_ACCOUNT, tax_type: XeroRuby::Accounting::TaxType::NONE,
                                                   tracking: [{ name: 'Cód. Proyecto', option: codename },
                                                              { name: 'Business', option: 'Training abierto' }] }],
                                    date:, due_date:, reference: codename,
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
                "#{e.message} - #{e.backtrace.grep_v(%r{/gems/}).join('\n')}")
        nil
      end
    end

    def invoice_paid?(invoice_id)
      invoice = get_invoice(invoice_id)
      invoice.amount_paid.positive?
    end

    def invoice_void?(invoice_id)
      invoice = get_invoice(invoice_id)
      invoice.status == 'VOIDED'
    end

    def email_invoice(invoice)
      @client.email_invoice(invoice.invoice_id)
    rescue StandardError => e
      Log.log(:xero, :warn,
              "invoice not sent :#{invoice.invoice_number}",
              "#{e.message} - #{e.backtrace.grep_v(%r{/gems/}).join('\n')}")
    end

    # <XeroRuby::Accounting::Invoice:0x00007f48103bce50
    # @has_attachments=false, @has_errors=false, @type="ACCREC",
    # @contact=#<XeroRuby::Accounting::Contact:0x00007f48103bc9f0 @has_attachments=false, @has_validation_errors=false, @contact_id="d924654e-b0c8-4dc4-b107-1bc496eeb0f0", @contact_status="ACTIVE", @name="José Pablo Escalona Sigall", @first_name="José Pablo", @last_name="Escalona Sigall", @email_address="jose.escalona@segurossura.cl", @contact_persons=[], @bank_account_details="", @addresses=[#<XeroRuby::Accounting::Address:0x000056258ee0bfa0 @address_type="STREET", @address_line1="Avenida Providencia 1760, Providencia, Chile", @city="", @region="", @postal_code="", @country="">,
    # <XeroRuby::Accounting::Address:0x000056258ee0aee8 @address_type="POBOX", @city="", @region="", @postal_code="", @country="">],
    #  @phones=[#<XeroRuby::Accounting::Phone:0x000056258ee0a128 @phone_type="DEFAULT", @phone_number="", @phone_area_code="", @phone_country_code="">,
    # <XeroRuby::Accounting::Phone:0x000056258ee097f0 @phone_type="DDI", @phone_number="", @phone_area_code="", @phone_country_code="">,
    # <XeroRuby::Accounting::Phone:0x000056258ee091d8 @phone_type="FAX", @phone_number="", @phone_area_code="", @phone_country_code="">,
    # <XeroRuby::Accounting::Phone:0x000056258ee08800 @phone_type="MOBILE", @phone_number="", @phone_area_code="", @phone_country_code="">],
    # @is_supplier=false, @is_customer=true, @sales_tracking_categories=[], @purchases_tracking_categories=[], @payment_terms=#<XeroRuby::Accounting::PaymentTerm:0x00007f48103d7a70 @sales=#<XeroRuby::Accounting::Bill:0x00007f48103d7890 @day=7, @type="DAYSAFTERBILLDATE">>,
    # @updated_date_utc=Tue, 06 Dec 2022 12:04:31 +0000, @contact_groups=[]>,
    # @line_items=[#<XeroRuby::Accounting::LineItem:0x00007f48103d6490 @line_item_id="38d9caa9-b6b9-4fb8-acbe-d1f7b19675f1", @description="Certified Scrum Master (CSM) -  OnLine  - 16-17 Ene - por una vacante de José Pablo  Escalona Sigall", @quantity=0.1e1, @unit_amount=0.76e3, @account_code="4300", @tax_type="NONE", @tax_amount=0.0, @line_amount=0.76e3, @tracking=[#<XeroRuby::Accounting::LineItemTracking:0x00007f48103d5ae0 @tracking_category_id="63a79b77-227b-4144-9be8-06e7a839d946", @tracking_option_id="10b15085-b05a-45dc-9d53-d53ac82db0f3", @name="Cód. Proyecto", @option="CSMOL230116">]>], @date=Tue, 06 Dec 2022, @due_date=Tue, 13 Dec 2022, @line_amount_types="Exclusive", @invoice_number="INV-0736", @reference="CSMOL230116", @branding_theme_id="fc426c1a-bbd1-4725-a973-3ead6fde8a60", @currency_code="USD", @currency_rate=0.1e1, @status="PAID", @sent_to_contact=true, @sub_total=0.76e3, @total_tax=0.0, @total=0.76e3, @invoice_id="6f352e28-585f-4ccd-a952-560a8f0e5af0", @is_discounted=false, @payments=[#<XeroRuby::Accounting::Payment:0x000056258edee680 @has_account=false, @has_validation_errors=false, @date=Tue, 06 Dec 2022,
    # @currency_rate=0.1e1, @amount=0.76e3, @reference="ch_3MC7zDEk2xEcmum71RUKjHGV", @payment_id="962ca9e8-0eb1-4639-ab9f-9ea9338c0cc1">],
    # @prepayments=[], @overpayments=[],
    # @amount_due=0.0, @amount_paid=0.76e3, @fully_paid_on_date=Tue, 06 Dec 2022, @updated_date_utc=Tue, 06 Dec 2022 20:43:37 +0000, @attachments=[]>
    def get_invoice(invoice_id)
      @client.get_invoice(invoice_id)
    end

    def get_online_invoice_url(invoice)
      return nil if invoice.nil?

      data = @client.get_online_invoice(invoice.invoice_id)
      data.online_invoices[0].online_invoice_url
    end
  end

  class TrackingCategories
    def initialize(client)
      @client = client
      @tracking_tategory_name = 'Cód. Proyecto'
      @tracking_category_id = '63a79b77-227b-4144-9be8-06e7a839d946'
    end

    def validate_or_create(option_name)
      return if valid? option_name

      create option_name
    end

    def valid?(option_name)
      response = @client.get_tracking_category(@tracking_category_id)

      !!response.tracking_categories[0].options.find { |e| e.name == option_name }
    rescue XeroRuby::ApiError => e
      Log.log(:xero, :warn,
              "category cant be read:#{option_name}",
              "#{e.message} - #{e.backtrace.grep_v(%r{/gems/}).join('\n')}")
    end

    def create(option_name)
      trackingOption = {
        name: option_name
      }

      begin
        @client.create_tracking_options(@tracking_category_id, trackingOption)
      rescue XeroRuby::ApiError => e
        Log.log(:xero, :warn,
                "category option not created:#{option_name}",
                "#{e.message} - #{e.backtrace.grep_v(%r{/gems/}).join('\n')}")
      end
    end
  end

  def self.create_null(...)
    NullXero.new(...)
  end

  def self.create_xero
    Xero.new
  end

  class Xero
    attr_reader :tenant_id

    def initialize
      @xero_client,
      @tenant_id = XeroClientService.initialized_client
    end

    def get_invoice(invoice_id)
      # ensure_full_initialization
      @xero_client.accounting_api.get_invoice(@tenant_id, invoice_id).invoices[0]
    end

    def create_tracking_options(...)
      @xero_client.accounting_api.create_tracking_options(@tenant_id, ...)
    end

    def get_tracking_category(...)
      @xero_client.accounting_api.get_tracking_category(@tenant_id, ...)
    end

    def create_contacts(...)
      @xero_client.accounting_api.create_contacts(@tenant_id, ...)
    end

    def get_contacts(...)
      @xero_client.accounting_api.get_contacts(@tenant_id, ...)
    end

    def create_invoices(...)
      @xero_client.accounting_api.create_invoices(@tenant_id, ...).invoices.first
    end

    def email_invoice(invoice_id, request_empty = [], opts = {})
      @xero_client.accounting_api.email_invoice(@tenant_id, invoice_id, request_empty, opts)
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
      @xero_client.accounting_api.get_online_invoice(@tenant_id, invoice_id)
    end
  end
end

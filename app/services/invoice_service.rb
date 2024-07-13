class InvoiceService
  def initialize(participant)
    self.class.xero
    @participant = participant
    @lang = participant.event.event_type.lang
    @pih = ParticipantInvoiceHelper.new(participant, @lang)
  end

  def self.xero_service(xero_service)
    @@xero_service = xero_service
  end

  def self.xero
    @@xero_service = nil unless defined?(@@xero_service) # real infra
    @@xero = XeroClientService::XeroApi.new(@@xero_service || XeroClientService.create_xero)
  end

  def self.due_date(event, today = DateTime.now)
    start = event.date
    eb = event.eb_end_date
    eb = nil if eb.nil? || eb.to_date < today.to_date
    [
      today + 7,  # one week from now
      start - 1,  # one day before curse start date
      eb          # if eb > today
    ].reject(&:nil?).min
  end

  def create_send_invoice
    return nil if @participant.event.currency_iso_code != 'USD'

    contact = @@xero.create_contact(
      @participant.company_name, @participant.fname, @participant.lname,
      @participant.email, @participant.phone, @participant.address
    )

    return if contact.nil?

    @invoice = create_invoice(@participant, contact)

    return if @invoice.nil?

    @pih.update_participant(@invoice)
    # @@xero.email_invoice(@invoice) unless @participant.referer_code.present?
    @invoice
  end

  def get_online_invoice_url
    @@xero.get_online_invoice_url(@invoice)
  end

  def create_invoice(participant, contact)
    unit_price = participant.applicable_unit_price
    date = DateTime.now
    codename = participant.event.online_cohort_codename

    return nil if unit_price < 0.01

    begin
      invoice = @@xero.create_invoices(
        contact.contacts[0].contact_id,
        @pih.item_description, participant.quantity, unit_price,
        date.to_s, InvoiceService.due_date(participant.event).to_s, codename, @lang
      )
    rescue StandardError => e
      Log.log(:xero, :error,
              "contact:#{contact.contacts[0].contact_id}",
              e.message + ' - ' + e.backtrace.grep_v(%r{/gems/}).join('\n'))
      invoice = nil
    end
    invoice
  end
end

# frozen_string_literal: true

ALERT_MAIL = 'entrenamos@kleer.la'
ADMIN_MAIL = 'admin@kleer.la'

class EventMailer < ApplicationMailer
  default from: ALERT_MAIL
  add_template_helper(DashboardHelper)

  def participant_paid(participant)
    @participant = participant
    @lang =  participant.event.event_type.lang
    @pih = ParticipantInvoiceHelper.new(participant, @lang)
    
    # to: @participant.email
    mail( to: ADMIN_MAIL, 
          cc: ALERT_MAIL, 
          subject: I18n.t('mail.paid.subject', locale: @lang, event:@participant.event.event_type.name)
    ) do |format|
      format.text
      format.html { render layout: false }
    end
  end

  def participant_voided(participant)
    @participant = participant
    @lang =  participant.event.event_type.lang
    @pih = ParticipantInvoiceHelper.new(participant, @lang)
    
    # to: @participant.email
    mail(to: ADMIN_MAIL, cc: ALERT_MAIL, subject: "Kleer | Invoice voided #{@participant.event.event_type.name}") do |format|
      format.text
      format.html { render layout: false }
    end
    edit_registration_link = "http://eventos.kleer.la/events/#{@participant.event.id}/participants/#{@participant.id}/edit"

    mail(to: ADMIN_MAIL, cc: ALERT_MAIL, 
      subject: "[Keventer] Invoice voided #{@participant.event.event_type.name}: #{participant.fname} #{participant.lname}",
      body: "Invoice: #{participant.lname}  \nLink para editar: #{edit_registration_link}"
    )
  end

  def welcome_new_event_participant(participant)
    @participant = participant
    @lang =  participant.event.event_type.lang
    @pih = ParticipantInvoiceHelper.new(participant, @lang)
    unless participant.event.is_sold_out
      begin
        invoice = create_send_invoice(participant)
        @online_invoice_url = @@xero.get_online_invoice_url(invoice)
      rescue StandardError => e
        Log.log(:xero, :error,  
          "create_send_invoice:#{participant.fname + participant.lname}", 
          e.message + ' - ' + e.backtrace.grep_v(%r{/gems/}).join('\n')
         )
        return
      end
    end
    @markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(hard_wrap: true), autolink: true)
    mail(to: @participant.email, cc: ADMIN_MAIL, subject: "Kleer | #{@participant.event.event_type.name}") do |format|
      format.text
      format.html { render layout: 'event_mailer' }
    end
  end

  def send_certificate(participant, certificate_url_a4, certificate_url_letter)
    @participant = participant
    @certificate_link_a4 = certificate_url_a4
    @certificate_link_letter = certificate_url_letter
    @markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(hard_wrap: true), autolink: true)
    mail(to: @participant.email,
         subject: "Kleer | Certificado del #{@participant.event.event_type.name}") do |format|
      format.text
      format.html { render layout: 'event_mailer' }
    end
  end

  def alert_event_monitor(participant, edit_registration_link)
    @pih = ParticipantInvoiceHelper.new(participant, :es)
    event = participant.event
    event_info = event_data(event.event_type.name, event.country.name, event.human_date)
    extra_message = "Lista de espera, no se creó invoice" if event.is_sold_out

    body = contact_data(participant) +
           invoice_data(participant) +
           "\n#{extra_message} \nPuedes ver/editar el registro en #{edit_registration_link}"

    mail(to: event.monitor_email.presence || ALERT_MAIL,
         subject: "[Keventer] Nuevo registro a #{event_info}: #{participant.fname} #{participant.lname}",
         body: body)
  end

  def event_data(event_name, country, date)
    "#{event_name} en #{country} del #{date}"
  end

  def contact_data(participant)
    "Contact #{participant.fname} #{participant.lname}
  FName: #{participant.fname} / Lname: #{participant.lname}
  email: #{participant.email}
  phone: #{participant.phone}
  Nro fiscal:#{participant.id_number} / Dirección:#{participant.address}
  --------------\n"
  end

  def invoice_data(participant)
    unit_price = participant.event.price(participant.quantity, participant.created_at)

    online_payment = 'Online Payment' if participant.event.enable_online_payment
    codename = participant.event.online_cohort_codename
    # enable_online_payment
    # online_course_codename
    # online_cohort_codename

    "Código de referencia: #{participant.referer_code}
      Texto: \n#{@pih.item_description}
      Linea: #{participant.quantity} personas x #{unit_price} = #{participant.quantity * unit_price} COD: #{codename}\n
      #{online_payment}\n
      ---- Notas del participante:\n#{participant.notes}\n---- Fin Notas\n"
  end

  # -----------------------------
  # TODO: move code related to Xero to XeroClientService
  #
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

  def create_send_invoice(participant)
    EventMailer.xero

    contact = @@xero.create_contact(
      "#{participant.fname} #{participant.lname}", participant.fname, participant.lname,
      participant.email, participant.phone, participant.address
    )

    return if contact.nil?

    invoice = create_invoice(participant, contact)

    return if invoice.nil?
    @pih.update_participant(invoice)
    @@xero.email_invoice(invoice)
    invoice
  end

  def create_invoice(participant, contact)
    unit_price = participant.event.price(participant.quantity, participant.created_at)
    date = DateTime.now
    codename = participant.event.online_cohort_codename

    begin
      invoice = @@xero.create_invoices(
        contact.contacts[0].contact_id,
        @pih.item_description, participant.quantity, unit_price,
        date.to_s, EventMailer.due_date(participant.event).to_s, codename, @lang
      )
    rescue StandardError => e
      Log.log(:xero, :error,  
        "contact:#{contact.contacts[0].contact_id}", 
        e.message + ' - ' + e.backtrace.grep_v(%r{/gems/}).join('\n')
       )
      invoice = nil
    end
    invoice
  end

  #  End of code to be moved to XeroClientService
  # ----------------------------------------------
end

class ParticipantInvoiceHelper
  def initialize(participant, lang)
    @participant = participant
    @lang =  lang
  end

  #TODO: test & change languaje
  def item_description
    participant = @participant
    event_name = participant.event.event_type.name
    country = participant.event.country.name.tr('-', '')
    human_date = participant.event.human_date

    if participant.quantity == 1
      I18n.t('mail.invoice.item_one', locale: @lang,
        course: event_name, place: country, date: human_date, student_name: "#{participant.fname} #{participant.lname}"
      )
    else
      I18n.t('mail.invoice.item_more', locale: @lang,
        course: event_name, place: country, date: human_date, qty: participant.quantity
      )
    end
  end

  def update_participant(invoice)
    return if invoice.nil?
    participant = @participant

    participant.xero_invoice_number = invoice.invoice_number
    participant.invoice_id = invoice.invoice_id
    participant.save!
  end

end
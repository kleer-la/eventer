# frozen_string_literal: true

ALERT_MAIL = 'entrenamos@kleer.la'

class EventMailer < ApplicationMailer
  add_template_helper(DashboardHelper)

  def self.xero_service(xero_service)
    @@xero_service = xero_service
  end

  def self.xero
    @@xero_service = nil unless defined?(@@xero_service) # real infra
    @@xero = XeroClientService::XeroApi.new(@@xero_service || XeroClientService.create_xero)
  end

  def welcome_new_event_participant(participant)
    @participant = participant
    invoice = send_invoice(participant)
    update_participant(participant, invoice)
    @markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(hard_wrap: true), autolink: true)
    mail(to: @participant.email, subject: "Kleer | #{@participant.event.event_type.name}") do |format|
      format.text
      format.html { render layout: 'event_mailer2' }
    end
  end

  def update_participant(participant, invoice)
    return if invoice.nil?

    participant.xero_invoice_number = invoice.invoices[0].invoice_number
    participant.save!
  end

  def send_certificate(participant, certificate_url_a4, certificate_url_letter)
    @participant = participant
    @certificate_link_a4 = certificate_url_a4
    @certificate_link_letter = certificate_url_letter
    @markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(hard_wrap: true), autolink: true)
    mail(to: @participant.email,
         subject: "Kleer | Certificado del #{@participant.event.event_type.name}") do |format|
      format.text
      format.html { render layout: 'event_mailer2' }
    end
  end

  def alert_event_monitor(participant, edit_registration_link)
    event = participant.event
    event_info = event_data(event.event_type.name, event.country.name, event.human_date)
    body = contact_data(participant) +
           invoice_data(participant) +
           "\n\nPuedes ver/editar el registro en #{edit_registration_link}"

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

    "Contact #{participant.fname} #{participant.lname}
      Código de referencia: #{participant.referer_code}
      Texto: \n#{description(participant)}
      Linea: #{participant.quantity} personas x #{unit_price} = #{participant.quantity * unit_price} COD: #{codename}\n
      #{online_payment}\n
      ---- Notas del participante:\n#{participant.notes}\n---- Fin Notas\n"
  end

  def send_invoice(participant)
    EventMailer.xero

    contact = @@xero.create_contact(
      "#{participant.fname} #{participant.lname}", participant.fname, participant.lname,
      participant.email, participant.phone, participant.address
    )

    return if contact.nil?

    unit_price = participant.event.price(participant.quantity, participant.created_at)
    date = participant.event.date
    due_date = date + 7
    codename = participant.event.online_cohort_codename

    # TODO: add participant notes
    begin
      invoice = @@xero.create_invoices(
        contact.contacts[0].contact_id,
        description(participant), participant.quantity, unit_price,
        date.to_s, due_date.to_s, codename
      )
    rescue NoMethodError => e
      print_exception(e, true)
      invoice = nil
    end
    invoice
  end

  def description(participant)
    event_name = participant.event.event_type.name
    country = participant.event.country.name.tr('-', '')
    human_date = participant.event.human_date
    participant_text = if participant.quantity == 1
                         " por una vancante de #{participant.fname} #{participant.lname}"
                       else
                         " por #{participant.quantity} vancantes"
                       end

    "#{event_name} - #{country} - #{human_date} -\n#{participant_text}"
  end
end

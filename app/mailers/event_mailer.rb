# frozen_string_literal: true

ALERT_MAIL = 'entrenamos@kleer.la'

class EventMailer < ApplicationMailer
  add_template_helper(DashboardHelper)

  def self.xero(xero_service = nil)
    (@@xero = XeroClientService::XeroApi.new(xero_service || XeroClientService.create_xero())) unless defined? @@xero
  end

  def welcome_new_event_participant(participant)
    @participant = participant
    send_invoice(participant)
    @markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(hard_wrap: true), autolink: true)
    mail(to: @participant.email, subject: "Kleer | #{@participant.event.event_type.name}") do |format|
      format.text
      format.html { render layout: 'event_mailer2' }  
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
    participant_text = if participant.quantity == 1
                         " por una vancante de #{participant.fname} #{participant.lname}"
                       else
                         " por #{participant.quantity} vancantes"
                       end

    event_name = participant.event.event_type.name
    country = participant.event.country.name.tr('-', '')
    human_date = participant.event.human_date
    online_payment = 'Online Payment' if participant.event.enable_online_payment
    codename = participant.event.online_cohort_codename
    # enable_online_payment
    # online_course_codename
    # online_cohort_codename

    "Contact #{participant.fname} #{participant.lname}
      Código de referencia: #{participant.referer_code}
      Texto:
      #{event_name} - #{country} - #{human_date} -
      #{participant_text}
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
    return if contact.has_validation_errors
    # create_invoice ...
  end



end

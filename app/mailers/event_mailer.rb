# frozen_string_literal: true

ALERT_MAIL = 'entrenamos@kleer.la'

class EventMailer < ApplicationMailer
  add_template_helper(DashboardHelper)

  def welcome_new_event_participant(participant)
    @participant = participant
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
    body = event_info +
           contact_data(participant) +
           invoice_data(participant) +
           "\nPuedes ver/editar el registro en #{edit_registration_link}"

    mail(to: event.monitor_email.presence || ALERT_MAIL,
         subject: "[Keventer] Nuevo registro a #{event_info}: #{participant.fname} #{participant.lname}",
         body: body)
  end

  def event_data(event_name, country, date)
    "#{event_name} en #{country} del #{date}"
  end

  def contact_data(participant)
    "\n#{participant.fname} #{participant.lname} (#{participant.email} #{participant.phone})\n"
  end

  def invoice_data(participant)
    unit_price = participant.event.price(participant.quantity, participant.created_at)
    body = "Nro fiscal:#{participant.id_number} / Dirección:#{participant.address}\n"
    body += "Código de referencia: #{participant.referer_code}\n" if participant.referer_code.present?
    body += "Cantidad y precio: #{participant.quantity} personas x #{unit_price} = #{participant.quantity * unit_price}\n"
    body + "---- Notas del participante:\n#{participant.notes}\n---- Fin Notas\n"
  end
end

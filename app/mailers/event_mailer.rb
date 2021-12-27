# frozen_string_literal: true

AlertMail = 'entrenamos@kleer.la'

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

  def send_certificate(participant, certificate_url_A4, certificate_url_LETTER)
    @participant = participant
    @certificate_link_A4 = certificate_url_A4
    @certificate_link_LETTER = certificate_url_LETTER
    @markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(hard_wrap: true), autolink: true)
    mail(to: @participant.email,
         subject: "Kleer | Certificado del #{@participant.event.event_type.name}") do |format|
      format.text
      format.html { render layout: 'event_mailer2' }
    end
  end

  def alert_event_monitor(participant, edit_registration_link)
    @participant = participant
    event = @participant.event
    event_title = "#{event.event_type.name} en #{event.country.name}"
    newbie = "#{@participant.fname} #{@participant.lname}"
    contact = "#{@participant.email}, #{@participant.phone}"
    body = "#{newbie} (#{contact}) se registró a #{event_title} del #{event.human_date}.\n"
    unless @participant.referer_code.nil? || @participant.referer_code.to_s == ''
      body += "Código de referencia: #{@participant.referer_code}\n"
    end
    if !@participant.notes.nil? && @participant.notes.to_s != ''
      body += "Notas del participante:\n"
      body += "------------------------------------\n"
      body += "#{@participant.notes}\n"
      body += "------------------------------------\n"
    end
    body += "Puedes ver/editar el registro en #{edit_registration_link}"
    mail_to = event.monitor_email.presence || AlertMail
    mail(to: mail_to,
         subject: "[Keventer] Nuevo registro a #{event_title} del #{event.human_date}: " + newbie,
         body: body)
  end
end

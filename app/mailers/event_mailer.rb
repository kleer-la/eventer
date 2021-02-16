# encoding: utf-8

class EventMailer < ActionMailer::Base
  default from: "entrenamos@kleer.la"

  add_template_helper(DashboardHelper)

  #TODO: quitar funcionalidad de webinars
  def welcome_new_webinar_participant(participant)
    @participant = participant
    mail(to: @participant.email, from: "Eventos <eventos@kleerer.com>", subject: "Kleer | #{@participant.event.event_type.name}" )
  end

  #TODO: quitar funcionalidad de webinars
  def notify_webinar_start(participant, webinar_link)
    @participant = participant
    @webinar_link = webinar_link
    mail(to: @participant.email, from: "Eventos <eventos@kleerer.com>", subject: "Kleer | Estamos iniciando! Sumate al webinar #{@participant.event.event_type.name}" )
  end

  def welcome_new_event_participant(participant)
    @participant = participant
    @markdown_renderer = Redcarpet::Markdown.new( Redcarpet::Render::HTML.new(:hard_wrap => true), :autolink => true)
    mail(to: @participant.email, subject: "Kleer | #{@participant.event.event_type.name}") do |format|
      format.text
      format.html { render :layout => 'event_mailer2' }
    end
  end

  def send_certificate(participant, certificate_url_A4, certificate_url_LETTER )
    @participant = participant
    @certificate_link_A4 = certificate_url_A4
    @certificate_link_LETTER = certificate_url_LETTER
    @markdown_renderer = Redcarpet::Markdown.new( Redcarpet::Render::HTML.new(:hard_wrap => true), :autolink => true)
    mail( to: @participant.email,
          subject: "Kleer | Certificado del #{@participant.event.event_type.name}")
  end

  def alert_event_monitor(participant, edit_registration_link)
    @participant = participant
    event= @participant.event
    event_title = event.event_type.name + ' en ' + event.country.name
    newbie = @participant.fname + ' ' + @participant.lname
    contact = @participant.email + ', ' + @participant.phone
    body = "#{newbie} (#{contact}) se registró a #{event_title} del #{event.human_date}.\n"
    body += "Código de referencia: #{@participant.referer_code}\n" unless (@participant.referer_code.nil? || @participant.referer_code.to_s == "")
    if (!@participant.notes.nil? && @participant.notes.to_s != "")
      body += "Notas del participante:\n"
      body += "------------------------------------\n"
      body += "#{@participant.notes}\n"
      body += "------------------------------------\n"
    end
    body += "Puedes ver/editar el registro en #{edit_registration_link}"
    mail(to: event.monitor_email,
        subject: "[Keventer] Nuevo registro a #{event_title} del #{event.human_date}: " + newbie,
        body: body
        ) unless event.monitor_email.to_s == ""    ## nil? || ''
  end

  def payment_process_result(participant,result,status)

    puts "------------------SENDING MAIL FOR PAYU CONFIRMATION ------------------"
    @participant = participant
    @result = result
    @status = status
    mail(to: "#{@participant.email}, #{@participant.event.monitor_email}",
         from: "Eventos <eventos@kleerer.com>",
         subject: "Kleer | Resultado del pago para: #{@participant.event.event_type.name}" )
  end

end

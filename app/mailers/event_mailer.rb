# frozen_string_literal: true

ALERT_MAIL = 'entrenamos@kleer.la'
ADMIN_MAIL = 'admin@kleer.la'

class EventMailer < ApplicationMailer
  default from: ALERT_MAIL
  helper DashboardHelper

  def participant_paid(participant)
    @participant = participant
    @lang = participant.event.event_type.lang
    @pih = ParticipantInvoiceHelper.new(participant, @lang)

    mail(to: participant.email,
         cc: "#{ADMIN_MAIL},#{ALERT_MAIL}",
         subject: I18n.t('mail.paid.subject', locale: @lang, event: @participant.event.event_type.name)) do |format|
      format.text
      format.html { render layout: false }
    end
  end

  def participant_voided(participant)
    @participant = participant
    @lang = participant.event.event_type.lang
    @pih = ParticipantInvoiceHelper.new(participant, @lang)

    # to: @participant.email
    edit_registration_link = "http://eventos.kleer.la/admin/events/#{@participant.event.id}/participants/#{@participant.id}/edit"

    mail(to: ADMIN_MAIL, cc: ALERT_MAIL,
         subject: "[Keventer] Invoice voided #{@participant.event.event_type.name}: #{participant.company_name}",
         body: "Invoice: #{participant.company_name}\n#{participant.fname} #{participant.lname} <#{participant.email}>\n\nLink para editar: #{edit_registration_link}")
  end

  def welcome_new_event_participant(participant)
    @participant = participant
    @lang = participant.event.event_type.lang
    @pih = ParticipantInvoiceHelper.new(participant, @lang)
    @online_invoice_url = participant.online_invoice_url

    @markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(hard_wrap: true), autolink: true)
    mail(to: @participant.email, cc: ADMIN_MAIL, subject: "Kleer | #{@participant.event.event_type.name}") do |format|
      format.text
      format.html { render layout: 'event_mailer' }
    end
  end

  def send_certificate(participant, _certificate_url_a4, certificate_url_letter)
    @participant = participant
    # @certificate_link_a4 = certificate_url_a4
    @certificate_link_letter = certificate_url_letter
    @markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(hard_wrap: true), autolink: true)
    mail(to: @participant.email,
         subject: "Kleer | Certificado del #{@participant.event.event_type.name}") do |format|
      format.text
      format.html { render layout: 'event_mailer' }
    end
  end

  def send_certificate_with_hr_notification(participant, _certificate_url_a4, certificate_url_letter, hr_emails: [], hr_message: nil)
    @participant = participant
    # @certificate_link_a4 = certificate_url_a4
    @certificate_link_letter = certificate_url_letter
    @hr_message = hr_message
    @markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(hard_wrap: true), autolink: true)
    
    # Clean and validate HR emails
    clean_hr_emails = hr_emails.map(&:strip).reject(&:blank?).select { |email| valid_email?(email) }
    
    mail_options = {
      to: @participant.email,
      subject: "Kleer | Certificado del #{@participant.event.event_type.name}"
    }
    
    # Add CC if HR emails are provided
    mail_options[:cc] = clean_hr_emails.join(', ') if clean_hr_emails.any?
    
    mail(mail_options) do |format|
      format.text { render 'send_certificate_with_hr' }
      format.html { render 'send_certificate_with_hr', layout: 'event_mailer' }
    end
  end

  def alert_event_monitor(participant, edit_registration_link)
    @pih = ParticipantInvoiceHelper.new(participant, :es)
    event = participant.event
    event_info = event_data(event.event_type.name, event.country.name, event.human_date)
    extra_message = 'Lista de espera, no se creó invoice' if event.is_sold_out

    body = contact_data(participant) +
           invoice_data(participant) +
           "\n#{extra_message} \nPuedes ver/editar el registro en #{edit_registration_link}"

    mail(to: event.monitor_email.presence || ALERT_MAIL,
         subject: "[Keventer] Nuevo registro a #{event_info}: #{participant.company_name}",
         body:)
  end

  private

  def valid_email?(email)
    email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
  end

  def event_data(event_name, country, date)
    "#{event_name} en #{country} del #{date}"
  end

  def contact_data(participant)
    "Contact #{participant.company_name}
  FName: #{participant.fname} / Lname: #{participant.lname}
  email: #{participant.email}
  phone: #{participant.phone}
  Nro fiscal:#{participant.id_number} / Dirección:#{participant.address}
  Código de descuento: #{participant.referer_code}
  --------------\n"
  end

  def invoice_data(participant)
    unit_price = participant.applicable_unit_price

    online_payment = 'Online Payment' if participant.event.enable_online_payment
    codename = participant.event.online_cohort_codename
    # enable_online_payment
    # online_course_codename
    # online_cohort_codename

    "Código de descuento: #{participant.referer_code}\n
      Texto: \n#{@pih.item_description}
      Linea: #{participant.quantity} personas x #{unit_price} = #{participant.quantity * unit_price} COD: #{codename}\n
      #{online_payment}\n
      ---- Notas del participante:\n#{participant.notes}\n---- Fin Notas\n"
  end
end

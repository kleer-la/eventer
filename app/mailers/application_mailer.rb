# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  # layout 'mailer'
  def contact_us(name, email, company, language, context, _subject, message)
    kleer_email = Setting.get(:CONTACT_US_MAILTO) || 'info@kleer.la'
    locale = (:en if language == 'en') || :es

    # Convert newlines to <br> tags for HTML email
    message_html = message.to_s.gsub(/\r\n|\r|\n/, "<br>\n")

    mail(
      from: kleer_email,
      to: kleer_email,
      subject: I18n.t('mail.contact_us.subject', locale:, name:)
    ) do |format|
      format.html { render html: I18n.t('mail.contact_us.body', locale:, message: message_html, context:, name:, email:, company:).html_safe }
      format.text { render plain: I18n.t('mail.contact_us.body_text', locale:, message:, context:, name:, email:, company:) }
    end
  end
end

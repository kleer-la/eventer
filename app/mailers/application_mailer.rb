# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  # default from: 'entrenamos@kleer.la'
  # layout 'mailer'
  def contact_us(name, email, context, _subject, message)
    kleer_email = Setting.get(:CONTACT_US_MAILTO) || 'info@kleer.la'
    locale = (:en if context.include?('/en/')) || :es

    mail(
      from: kleer_email,
      to: kleer_email,
      subject: I18n.t('mail.contact_us.subject', locale:, name: name),
      body: I18n.t('mail.contact_us.body', locale:, message: message,
                                           context: context, name: name, email: email)
    )
  end
end

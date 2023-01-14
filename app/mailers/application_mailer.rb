# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'entrenamos@kleer.la'
  # layout 'mailer'
  def contact_us(name, email, context, subject, message)

    mail(to: ENV['CONTACT_US_MAILTO'] || 'entrenamos@kleer.la',
      subject: "[Consulta] En #{context} por #{name}",
      body: "#{message} \n#{'-'*10}\n#{context}\n#{name}<#{email}>"
    )
  end
end

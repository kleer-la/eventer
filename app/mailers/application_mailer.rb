# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'entrenamos@kleer.la'
  # layout 'mailer'
  def contact_us(name, email, context, subject, message)

    unless self.class.valid_name?(name)
      Log.log(:mail, :info,  
        "Contact Us name:#{name}", 
        "#{email} #{context}, message: #{message}"
       )
      return
    end

    mail(to: ENV['CONTACT_US_MAILTO'] || 'entrenamos@kleer.la',
      subject: "[Consulta] #{name} consulto sobre #{context} #{subject}",
      body: "#{message} \n#{'-'*10}\n#{context}\n#{name}<#{email}>"
    )
  end

  def self.valid_name?(name)
    return false if name.to_s == ''
    name = name.strip
    return false if !!/^[a-z]+[A-Z]/.match(name)
    return false if !!/[a-z]+[A-Z]+[a-z]/.match(name)
    return false if name.length > 50
    true
  end
end

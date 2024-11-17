class NotificationMailer < ApplicationMailer
  def custom_notification(contact, template)
    @content = template.render_content(contact)
    mail(
      to: template.to,
      cc: template.cc,
      subject: template.subject
    )
  end

  def daily_digest(contacts, template)
    @contacts = contacts
    @content = template.render_content(contacts.first) # You might want to customize this
    mail(
      to: template.to,
      cc: template.cc,
      subject: "Daily Digest: #{template.subject}"
    )
  end
end

class NotificationMailer < ApplicationMailer
  def custom_notification(contact, template)
    @content = template.render_content(contact)
    rendered_to = template.render_field('to', contact)
    rendered_subject = template.render_field('subject', contact)
    rendered_cc = template.render_field('cc', contact)
    mail(
      to: rendered_to,
      cc: rendered_cc,
      subject: rendered_subject
    )
  end

  def daily_digest(contacts, template)
    @contacts = contacts
    @content = template.render_content(contacts.first)
    rendered_to = template.render_field('to', contacts.first)
    rendered_subject = template.render_field('subject', contacts.first)
    rendered_cc = template.render_field('cc', contacts.first)

    mail(
      to: rendered_to,
      cc: rendered_cc,
      subject: rendered_subject
    )
  end
end

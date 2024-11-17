class MailTemplate < ApplicationRecord
  enum trigger_type: { contact_form: 0, download_form: 1 }
  enum delivery_schedule: { immediate: 0, daily: 1 }

  validates :trigger_type, :identifier, :subject, :content, :to, presence: true
  validates :identifier, uniqueness: true

  def render_content(contact)
    template = Liquid::Template.parse(content)
    template.render(contact.form_data.with_indifferent_access)
  end
end

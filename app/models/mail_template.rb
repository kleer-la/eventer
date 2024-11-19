class MailTemplate < ApplicationRecord
  enum trigger_type: { contact_form: 0, download_form: 1 }
  enum delivery_schedule: { immediate: 0, daily: 1 }

  validates :identifier, presence: true, uniqueness: true
  validates :trigger_type, presence: true
  validates :to, presence: true
  validates :subject, presence: true
  validates :content, presence: true
  validates :delivery_schedule, presence: true

  def render_content(contact)
    template = Liquid::Template.parse(content)
    template.render(contact.form_data.with_indifferent_access)
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[active cc content created_at delivery_schedule id id_value identifier subject to
       trigger_type updated_at]
  end
end

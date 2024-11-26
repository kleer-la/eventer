class MailTemplate < ApplicationRecord
  enum trigger_type: { contact_form: 0, download_form: 1 }
  enum delivery_schedule: { immediate: 0, daily: 1 }
  enum lang: %i[es en]

  validates :identifier, presence: true, uniqueness: true
  validates :trigger_type, presence: true
  validates :to, presence: true
  validates :subject, presence: true
  validates :content, presence: true
  validates :delivery_schedule, presence: true

  def render_content(contact)
    render_field(:content, contact)
  end

  def render_field(field_name, contact)
    value = send(field_name)
    render_template(value, contact)
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[active cc content created_at delivery_schedule id id_value identifier subject to
       trigger_type updated_at]
  end

  private

  def render_template(template, contact)
    return template if template.blank?

    begin
      liquid_template = Liquid::Template.parse(template)
      liquid_template.render(contact.form_data.with_indifferent_access)
      # liquid_template.render(
      #   'contact' => contact.attributes,
      #   'form_data' => contact.form_data
      # )
    rescue Liquid::SyntaxError => e
      Rails.logger.error("Liquid syntax error in template: #{e.message}")
      template
    end
  end
end

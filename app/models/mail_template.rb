class MailTemplate < ApplicationRecord
  enum :trigger_type, { contact_form: 0, download_form: 1 }
  enum :delivery_schedule, { immediate: 0, daily: 1 }
  enum :lang, %i[es en]

  validates :identifier, presence: true, uniqueness: true
  validates :trigger_type, presence: true
  validates :to, presence: true
  validates :subject, presence: true
  validates :content, presence: true
  validates :delivery_schedule, presence: true

  # The templates to send for a contact: the immediate, active ones of its
  # trigger type and language — and, for a download, the resource's own when it
  # has any (resource_slug), the generic ones (no resource_slug) otherwise.
  def self.for(contact)
    candidates = where(trigger_type: contact.trigger_type, lang: (contact.form_data['language'] || 'es').to_sym,
                       active: true, delivery_schedule: 'immediate')
    own = contact.resource_slug.present? ? candidates.where(resource_slug: contact.resource_slug) : none
    own.any? ? own : candidates.where(resource_slug: nil)
  end

  def render_content(contact)
    render_field(:content, contact)
  end

  def render_field(field_name, contact)
    value = send(field_name)
    render_template(value, contact)
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[active cc content created_at delivery_schedule id id_value identifier resource_slug subject to
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

# frozen_string_literal: true

class GetMailTemplateTool < AuthenticatedTool
  tool_name 'get_mail_template'
  requires_permission :read, MailTemplate

  description <<~MD
    Returns one email template in full, by identifier or id, with `rendered`:
    subject, to and content as they come out for a sample contact, so the
    Liquid variables can be checked. Pass resource_slug to render it for a real
    resource (its titles and download links) instead of the sample one.
  MD

  # What the site's forms put in a contact, with sample values
  SAMPLE_CONTACT = {
    'name' => 'Ana García', 'email' => 'ana@example.com', 'company' => 'Ejemplo SA', 'language' => 'es',
    'message' => 'Hola, quiero más información.', 'page' => '/es/recursos/recurso-de-ejemplo',
    'resource_slug' => 'recurso-de-ejemplo', 'resource_title_es' => 'Recurso de ejemplo',
    'resource_title_en' => 'Sample resource', 'resource_getit_es' => 'https://www.kleer.la/ejemplo.pdf',
    'resource_getit_en' => 'https://www.kleer.la/sample.pdf'
  }.freeze

  arguments do
    required(:id).filled(:string).description('Template identifier (preferred) or numeric id')
    optional(:resource_slug).filled(:string).description('Render for this resource instead of the sample one')
  end

  def call(id:, resource_slug: nil)
    template = MailTemplate.find_by(identifier: id) || MailTemplate.find(id)
    contact = sample_contact(resource_slug)
    template.slice(:id, :identifier, :trigger_type, :lang, :resource_slug, :subject, :to, :cc, :content, :active,
                   :delivery_schedule, :updated_at)
            .merge(rendered: { subject: template.render_field(:subject, contact),
                               to: template.render_field(:to, contact), content: template.render_content(contact) })
            .to_json
  rescue ActiveRecord::RecordNotFound
    { status: 'error', errors: ["No mail template with identifier or id #{id.inspect}"] }.to_json
  end

  private

  def sample_contact(resource_slug)
    form_data = SAMPLE_CONTACT.dup
    if resource_slug.present?
      resource = Resource.friendly.find(resource_slug)
      form_data.merge!('resource_slug' => resource.slug, 'resource_title_es' => resource.title_es,
                       'resource_title_en' => resource.title_en, 'resource_getit_es' => resource.getit_es,
                       'resource_getit_en' => resource.getit_en, 'page' => "/es/recursos/#{resource.slug}")
    end
    Contact.new(trigger_type: :download_form, email: form_data['email'], form_data: form_data)
  end
end

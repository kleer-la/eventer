# frozen_string_literal: true

# One tool for the email templates the site's forms trigger, so the connector
# lists a single permission for them: operation says what to do.
class MailTemplatesTool < AuthenticatedTool
  tool_name 'mail_templates'
  requires_permission :read, MailTemplate

  OPERATIONS = %w[list get update create].freeze

  # What the site's forms put in a contact, with sample values, for `get`'s render
  SAMPLE_CONTACT = {
    'name' => 'Ana García', 'email' => 'ana@example.com', 'company' => 'Ejemplo SA', 'language' => 'es',
    'message' => 'Hola, quiero más información.', 'page' => '/es/recursos/recurso-de-ejemplo',
    'resource_slug' => 'recurso-de-ejemplo', 'resource_title_es' => 'Recurso de ejemplo',
    'resource_title_en' => 'Sample resource', 'resource_getit_es' => 'https://www.kleer.la/ejemplo.pdf',
    'resource_getit_en' => 'https://www.kleer.la/sample.pdf'
  }.freeze

  description <<~MD
    The email templates the site's forms trigger. Which ones go out for a
    submission is decided by trigger_type (contact_form or download_form), the
    contact's language, active and delivery_schedule (immediate or daily). For
    a download, a template with a resource_slug belongs to that resource and
    replaces the generic ones (no slug) whenever the resource has any.

    operation=list (default): filtered by trigger_type, lang, resource_slug, active.
    operation=get: one template in full, by id (identifier or numeric id), with
    `rendered` — subject, to and content as they come out for a sample contact,
    or for a real resource when resource_slug is given.
    operation=update: edits the template `id`; only the fields passed are
    touched, cc and resource_slug can be emptied with "". Prefer `replacements`
    to change part of the content.
    operation=create: identifier, trigger_type, lang, subject and content are
    required; active and immediate unless told otherwise.

    Writes take two steps: confirm=false (the default) validates and previews
    without saving, warning about Liquid variables the forms do not send; call
    again with confirm=true once the user agrees. Writing needs the admin role.
  MD

  arguments do
    optional(:operation).filled(:string).description("'list' (default), 'get', 'update' or 'create'")
    optional(:id).filled(:string).description('get/update: template identifier (preferred) or numeric id')
    optional(:identifier).filled(:string).description('create: unique identifier, e.g. session_handoff_es')
    optional(:trigger_type).filled(:string).description('contact_form | download_form (list: filter)')
    optional(:lang).filled(:string).description("'es' or 'en': sent to contacts who wrote in that language")
    optional(:resource_slug).value(:string)
                            .description('download_form only: the resource the template belongs to; "" = generic. ' \
                                         'list: filter. get: render for that resource')
    optional(:subject).filled(:string).description('Subject; Liquid variables allowed')
    optional(:content).filled(:string).description('Body (HTML); Liquid variables allowed')
    optional(:to).filled(:string).description('Recipient, default {{email}}')
    optional(:cc).value(:string).description('Copy recipients; "" clears')
    optional(:active).filled(:bool).description('list: filter. update/create: whether it is sent (create default true)')
    optional(:delivery_schedule).filled(:string).description('immediate (create default) | daily')
    optional(:limit).filled(:integer).description("list: how many (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
    optional(:confirm).filled(:bool).description('update/create: false (default) = preview only; true = save')
    instance_exec(&ApplicationTool::REPLACEMENTS)
  end

  def call(operation: 'list', id: nil, confirm: false, limit: DEFAULT_LIMIT, **fields)
    case operation
    when 'list' then list(limit: limit, **fields.slice(:trigger_type, :lang, :resource_slug, :active))
    when 'get' then get(id, resource_slug: fields[:resource_slug])
    when 'update' then write(find(id), confirm: confirm, **fields)
    when 'create' then write(nil, confirm: confirm, **{ to: '{{email}}' }.merge(fields))
    else unknown_operation(operation)
    end
  rescue ActiveRecord::RecordNotFound
    error("No mail template with identifier or id #{id.inspect}")
  end

  private

  def list(limit:, **filters)
    scope = MailTemplate.order(:trigger_type, :lang, :identifier).where(filters.compact)
    items = scope.limit(limit.clamp(1, MAX_LIMIT)).map { |template| summary(template) }
    listing(:templates, items, total: scope.count, narrow: 'trigger_type, lang, resource_slug or active')
  rescue ArgumentError => e
    error(e.message)
  end

  def get(id, resource_slug:)
    template = find(id)
    contact = sample_contact(resource_slug)
    template.slice(:id, :identifier, :trigger_type, :lang, :resource_slug, :subject, :to, :cc, :content, :active,
                   :delivery_schedule, :updated_at)
            .merge(rendered: { subject: template.render_field(:subject, contact),
                               to: template.render_field(:to, contact), content: template.render_content(contact) })
            .to_json
  end

  def write(template, confirm:, **fields)
    action = template ? :update : :create
    return unauthorized(action, MailTemplate) unless ability.can?(action, MailTemplate)

    MailTemplateWriteService.new(ability: ability, record: template, **fields).call(confirm: confirm).to_json
  end

  def find(id)
    raise ActiveRecord::RecordNotFound if id.blank?

    MailTemplate.find_by(identifier: id) || MailTemplate.find(id)
  end

  def summary(template)
    template.slice(:id, :identifier, :trigger_type, :lang, :resource_slug, :subject, :to, :active,
                   :delivery_schedule, :updated_at)
  end

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

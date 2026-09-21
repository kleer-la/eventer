# frozen_string_literal: true

class ListMailTemplatesTool < AuthenticatedTool
  tool_name 'list_mail_templates'
  requires_permission :read, MailTemplate

  description <<~MD
    Lists the email templates the site's forms trigger. Which ones go out for a
    submission is decided by trigger_type (contact_form or download_form), the
    contact's language, active and delivery_schedule (immediate or daily).

    For a download, a template with a resource_slug belongs to that resource
    and replaces the generic ones (no slug) whenever the resource has any.
  MD

  arguments do
    optional(:trigger_type).filled(:string).description('contact_form | download_form')
    optional(:lang).filled(:string).description("'es' or 'en'")
    optional(:resource_slug).filled(:string).description("A resource's own templates")
    optional(:active).filled(:bool).description('true = only active, false = only inactive')
    optional(:limit).filled(:integer).description("How many to return (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
  end

  def call(trigger_type: nil, lang: nil, resource_slug: nil, active: nil, limit: DEFAULT_LIMIT)
    scope = MailTemplate.order(:trigger_type, :lang, :identifier)
    scope = scope.where(trigger_type: trigger_type) if trigger_type.present?
    scope = scope.where(lang: lang) if lang.present?
    scope = scope.where(resource_slug: resource_slug) if resource_slug.present?
    scope = scope.where(active: active) unless active.nil?

    items = scope.limit(limit.clamp(1, MAX_LIMIT)).map { |template| summary(template) }
    listing(:templates, items, total: scope.count, narrow: 'trigger_type, lang, resource_slug or active')
  rescue ArgumentError => e
    { status: 'error', errors: [e.message] }.to_json
  end

  private

  def summary(template)
    template.slice(:id, :identifier, :trigger_type, :lang, :resource_slug, :subject, :to, :active,
                   :delivery_schedule, :updated_at)
  end
end

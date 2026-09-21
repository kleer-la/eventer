# frozen_string_literal: true

class CreateMailTemplateTool < AuthenticatedTool
  tool_name 'create_mail_template'
  requires_permission :create, MailTemplate

  description <<~MD
    Creates an email template for a form. It is active and sent immediately
    unless told otherwise. A download_form template with a resource_slug is
    that resource's own and replaces the generic download templates for it.

    Two steps: confirm=false (the default) previews without saving, warning
    about Liquid variables the forms do not send.
  MD

  arguments do
    required(:identifier).filled(:string).description('Unique identifier, e.g. session_handoff_es')
    required(:trigger_type).filled(:string).description('contact_form | download_form')
    required(:lang).filled(:string).description("'es' or 'en': sent to contacts who wrote in that language")
    required(:subject).filled(:string).description('Subject; Liquid variables allowed')
    required(:content).filled(:string).description('Body (HTML); Liquid variables allowed')
    optional(:to).filled(:string).description('Recipient, default {{email}}')
    optional(:cc).filled(:string).description('Copy recipients')
    optional(:resource_slug).filled(:string).description('download_form only: the resource this template belongs to')
    optional(:active).filled(:bool).description('default true')
    optional(:delivery_schedule).filled(:string).description('immediate (default) | daily')
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = save')
  end

  def call(confirm: false, to: '{{email}}', **fields)
    MailTemplateWriteService.new(ability: ability, to: to, **fields).call(confirm: confirm).to_json
  end
end

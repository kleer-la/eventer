# frozen_string_literal: true

class UpdateMailTemplateTool < AuthenticatedTool
  tool_name 'update_mail_template'
  requires_permission :update, MailTemplate

  description <<~MD
    Edits an email template, by identifier or id. Only the fields you pass are
    touched; cc and resource_slug can be emptied with "".

    Two steps: confirm=false (the default) validates and returns a preview of
    what would change, saving nothing; call again with confirm=true once the
    user agrees. The preview warns about Liquid variables the forms do not
    send. To change part of the content, prefer `replacements` over resending
    it whole.
  MD

  arguments do
    required(:id).filled(:string).description('Template identifier (preferred) or numeric id')
    optional(:identifier).filled(:string).description('New unique identifier')
    optional(:trigger_type).filled(:string).description('contact_form | download_form')
    optional(:lang).filled(:string).description("'es' or 'en'")
    optional(:resource_slug).value(:string)
                            .description("download_form only: the resource this template belongs to; \"\" = generic")
    optional(:subject).filled(:string).description('Subject; Liquid variables allowed')
    optional(:content).filled(:string).description('Body (HTML); Liquid variables allowed')
    optional(:to).filled(:string).description('Recipient, usually {{email}}')
    optional(:cc).value(:string).description('Copy recipients; "" clears')
    optional(:active).filled(:bool)
    optional(:delivery_schedule).filled(:string).description('immediate | daily')
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = save')
    instance_exec(&ApplicationTool::REPLACEMENTS)
  end

  def call(id:, confirm: false, **fields)
    template = MailTemplate.find_by(identifier: id) || MailTemplate.find(id)
    MailTemplateWriteService.new(ability: ability, record: template, **fields).call(confirm: confirm).to_json
  rescue ActiveRecord::RecordNotFound
    { status: 'error', errors: ["No mail template with identifier or id #{id.inspect}"] }.to_json
  end
end

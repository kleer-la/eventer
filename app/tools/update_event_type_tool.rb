# frozen_string_literal: true

class UpdateEventTypeTool < AuthenticatedTool
  tool_name 'update_event_type'
  requires_permission :update, EventType

  description <<~MD
    Edits a course type, looked up by slug or id. Only the fields you pass are
    touched. Read it with get_event_type first, so the change is made against
    the current text.

    To change part of a block, prefer `replacements` over resending it whole. It
    patches description, recipients, program, goal, learnings, takeaways and
    faq — which is how a stale link inside a course page gets fixed.

    Whether a course is on sale on the site is not an argument here: that is a
    decision about what Kleer sells, and it is made from the admin.

    Two steps: confirm=false (the default) validates and returns a preview
    without saving; call again with confirm=true once the user agrees.
  MD

  arguments do
    required(:id).filled(:string).description('Course slug (preferred) or numeric id')
    optional(:name).filled(:string).description('Course name, as it reads on the certificate')
    optional(:description).filled(:string).description('What the course is')
    optional(:recipients).filled(:string).description('Who it is for')
    optional(:program).filled(:string).description('Contents')
    optional(:elevator_pitch).filled(:string).description('One-line pitch, at most 160 characters')
    optional(:goal).filled(:string).description('Objective')
    optional(:learnings).filled(:string).description('What the participant learns')
    optional(:takeaways).filled(:string).description('What the participant takes home')
    optional(:faq).filled(:string)
                  .description('Questions and answers, each one an `<h4>` heading followed by its answer')
    optional(:subtitle).filled(:string).description('Subtitle')
    optional(:tag_name).filled(:string).description('Short tag used in listings')
    optional(:duration).filled(:integer).description('Hours, the number printed on the certificate')
    optional(:lang).filled(:string).description("Language of the course: 'es' or 'en'")
    optional(:trainers).array(:string).description('Trainer names, exactly as they are in the admin')
    optional(:is_kleer_certification).filled(:bool)
                                     .description('true = it grants a Kleer certification')
    optional(:kleer_cert_seal_image).filled(:string).description('Seal image file name for the certificate')
    optional(:csd_eligible).filled(:bool).description('true = counts towards Scrum Alliance CSD')
    optional(:new_version).filled(:bool).description('true = the newer edition of the course')
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = save')
    instance_exec(&ApplicationTool::REPLACEMENTS)
  end

  def call(id:, confirm: false, trainers: nil, **fields)
    event_type = find(id)
    EventTypeWriteService.new(ability: ability, record: event_type, trainers: trainers, **fields)
                         .call(confirm: confirm).to_json
  rescue ActiveRecord::RecordNotFound
    { status: 'error', errors: ["No course type with slug or id #{id.inspect}"] }.to_json
  end

  private

  # The slug is derived, not stored — "<id>-<name parameterised>" — so a lookup
  # takes the leading id and a bare id works too.
  def find(id)
    EventType.find(id.to_s[/\A\d+/] || id)
  end
end

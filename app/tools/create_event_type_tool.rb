# frozen_string_literal: true

class CreateEventTypeTool < AuthenticatedTool
  tool_name 'create_event_type'
  requires_permission :create, EventType

  description <<~MD
    Creates a course type: the template an event is given from, and the name,
    duration and seal that end up printed on the certificate.

    Look for an existing one with list_event_types first — a course given twice
    is two events of one type, not two types.

    It is always created out of the public catalog: putting a course on sale on
    the site is done from the admin, on purpose.

    Two steps: confirm=false (the default) validates and returns a preview
    without saving; call again with confirm=true once the user agrees.
  MD

  arguments do
    required(:name).filled(:string).description('Course name, as it should read on the certificate')
    required(:description).filled(:string).description('What the course is')
    required(:recipients).filled(:string).description('Who it is for')
    required(:program).filled(:string).description('Contents')
    required(:elevator_pitch).filled(:string).description('One-line pitch, at most 160 characters')
    required(:trainers).array(:string).description('Trainer names, exactly as they are in the admin')
    optional(:duration).filled(:integer).description('Hours, the number printed on the certificate')
    optional(:lang).filled(:string).description("Language of the course: 'es' or 'en' (defaults to es)")
    optional(:goal).filled(:string).description('Objective')
    optional(:learnings).filled(:string).description('What the participant learns')
    optional(:takeaways).filled(:string).description('What the participant takes home')
    optional(:tag_name).filled(:string).description('Short tag used in listings')
    optional(:subtitle).filled(:string).description('Subtitle')
    optional(:is_kleer_certification).filled(:bool)
                                     .description('true = a Kleer certification; needs kleer_cert_seal_image')
    optional(:kleer_cert_seal_image).filled(:string).description('Seal image file name for the certificate')
    optional(:csd_eligible).filled(:bool).description('true = counts towards Scrum Alliance CSD')
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = save')
  end

  def call(confirm: false, **fields)
    EventTypeWriteService.new(ability: ability, **fields).call(confirm: confirm).to_json
  end
end

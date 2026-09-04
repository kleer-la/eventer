# frozen_string_literal: true

class CreateParticipantTool < AuthenticatedTool
  tool_name 'create_participant'
  requires_permission :create, Participant

  description <<~MD
    Registers a person in an event — typically someone who was in the room but
    never in the system, and now needs their certificate.

    Set status to A (Presente) or K (Certificado) for a course already given:
    those are the only two states a certificate can be issued from. Without it
    the person is left as N (Nuevo), a fresh registration.

    Saving returns the verification code the certificate will carry.

    Two steps: confirm=false (the default) validates and returns a preview
    without saving; call again with confirm=true once the user agrees.
  MD

  arguments do
    required(:event_id).filled(:integer).description('Event id, from list_events')
    required(:fname).filled(:string).description('First name, as it should read on the certificate')
    required(:lname).filled(:string).description('Last name, as it should read on the certificate')
    required(:email).filled(:string).description('E-mail')
    optional(:status).filled(:string).description('N, T, C, A (Presente), K (Certificado), D or X. Defaults to N')
    optional(:phone).filled(:string).description('Phone')
    optional(:id_number).filled(:string).description('National ID number')
    optional(:address).filled(:string).description('Address')
    optional(:company_name).filled(:string).description('Company')
    optional(:influence_zone).filled(:string).description('Influence zone, by tag name or zone name')
    optional(:notes).filled(:string).description('Internal notes')
    optional(:quantity).filled(:integer).description('Seats bought (defaults to 1)')
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = save')
  end

  def call(confirm: false, **fields)
    ParticipantWriteService.new(ability: ability, **fields).call(confirm: confirm).to_json
  end
end

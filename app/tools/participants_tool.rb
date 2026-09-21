# frozen_string_literal: true

# Participants — people registered in an event — and their certificates: one
# tool, three operations.
class ParticipantsTool < AuthenticatedTool
  tool_name 'participants'
  requires_permission :read, Participant

  OPERATIONS = %w[search create issue_certificate].freeze

  description <<~MD
    People registered in a course, and their certificates.

    operation=search (default): by query (name, e-mail or verification code)
    and/or event_id, optionally status. One of query or event_id is required:
    this never lists everyone. Answers each one's verification code — what is
    typed at kleer.la/certificado — and whether the certificate can be issued.
    operation=create: registers a person in event_id (fname, lname, email
    required) — typically someone who was in the room but never in the
    system, and now needs their certificate. Set status to A (Presente) or K
    (Certificado) for a course already given: the only states a certificate
    can be issued from; without it the person is N (Nuevo). Saving returns the
    verification code.
    operation=issue_certificate: renders participant_id's A4 and LETTER PDFs
    and uploads them to S3, which is what makes the code verifiable at
    kleer.la/certificado. Mails nothing unless notify=true. The participant has
    to be A or K, and the event's first trainer needs a signature image.

    Writes take two steps: confirm=false (the default) checks and previews
    without doing anything; call again with confirm=true once the user agrees.
  MD

  arguments do
    optional(:operation).filled(:string).description("'search' (default), 'create' or 'issue_certificate'")
    optional(:query).filled(:string).description('search: matched against name, e-mail and verification code')
    optional(:event_id).filled(:integer).description('search: filter. create: the event, from events')
    optional(:status).filled(:string).description('search: filter; create: N, T, C, A (Presente), K (Certificado), D or X')
    optional(:limit).filled(:integer).description("search: how many (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
    optional(:participant_id).filled(:integer).description('issue_certificate: participant id, from search')
    optional(:notify).filled(:bool).description('issue_certificate: true = also mail the certificate')
    optional(:fname).filled(:string).description('First name, as it should read on the certificate')
    optional(:lname).filled(:string).description('Last name, as it should read on the certificate')
    optional(:email).filled(:string).description('E-mail')
    optional(:phone).filled(:string).description('Phone')
    optional(:id_number).filled(:string).description('National ID number')
    optional(:address).filled(:string).description('Address')
    optional(:company_name).filled(:string).description('Company')
    optional(:influence_zone).filled(:string).description('Influence zone, by tag name or zone name')
    optional(:notes).filled(:string).description('Internal notes')
    optional(:quantity).filled(:integer).description('Seats bought (defaults to 1)')
    optional(:confirm).filled(:bool).description('create/issue_certificate: false (default) = preview; true = do it')
  end

  def call(operation: 'search', confirm: false, limit: DEFAULT_LIMIT, participant_id: nil, notify: false, **fields)
    case operation
    when 'search' then search(limit: limit, **fields.slice(:query, :event_id, :status))
    when 'create' then create(confirm: confirm, **fields.except(:query))
    when 'issue_certificate' then issue_certificate(participant_id, notify: notify, confirm: confirm)
    else unknown_operation(operation)
    end
  end

  private

  def search(limit:, query: nil, event_id: nil, status: nil)
    if query.blank? && event_id.blank?
      return error('Give a query (name, e-mail or verification code) or an event_id. ' \
                   'participants does not list every participant.')
    end

    scope = filtered(query, event_id, status)
    participants = scope.limit(limit.clamp(1, MAX_LIMIT)).map { |participant| summary(participant) }
    listing(:participants, participants, total: scope.count, narrow: 'query, event_id or status')
  end

  def filtered(query, event_id, status)
    scope = Participant.includes(event: :event_type).order(created_at: :desc)
    if query.present?
      term = "%#{query.downcase}%"
      scope = scope.where("LOWER(fname || ' ' || lname) LIKE :t OR LOWER(email) LIKE :t OR " \
                          'LOWER(verification_code) LIKE :t', t: term)
    end
    scope = scope.where(event_id: event_id) if event_id.present?
    scope = scope.where(status: status) if status.present?
    scope
  end

  def summary(participant)
    blockers = CertificateIssueService.blockers(participant)
    { id: participant.id, name: "#{participant.fname} #{participant.lname}", email: participant.email,
      status: participant.status, status_desc: participant.human_status,
      event_id: participant.event_id, event: participant.event&.event_type&.name,
      date: participant.event&.date, verification_code: participant.verification_code,
      certificate_ready: blockers.empty?, certificate_blocked_by: blockers.presence }.compact
  end

  def create(confirm:, **fields)
    return unauthorized(:create, Participant) unless ability.can?(:create, Participant)

    ParticipantWriteService.new(ability: ability, **fields).call(confirm: confirm).to_json
  end

  def issue_certificate(participant_id, notify:, confirm:)
    return unauthorized(:update, Participant) unless ability.can?(:update, Participant)

    participant = Participant.find_by(id: participant_id)
    if participant.nil?
      return error("Unknown participant #{participant_id.inspect}. Use operation=search to find them.")
    end

    CertificateIssueService.new(participant: participant, notify: notify).call(confirm: confirm).to_json
  end
end

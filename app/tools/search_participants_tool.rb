# frozen_string_literal: true

class SearchParticipantsTool < AuthenticatedTool
  tool_name 'search_participants'
  requires_permission :read, Participant

  description <<~MD
    Finds people registered in a course, by name, e-mail or verification code,
    or lists the ones in a given event.

    It answers with each one's verification code — what is typed at
    kleer.la/certificado — and whether their certificate can be issued yet.

    A search term or an event id is required: this never lists everyone.
  MD

  arguments do
    optional(:query).filled(:string).description('Matched against name, e-mail and verification code')
    optional(:event_id).filled(:integer).description('Only participants of this event')
    optional(:status).filled(:string).description('Only this status: N, T, C, A, K, D or X')
    optional(:limit).filled(:integer).description("How many to return (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
  end

  def call(query: nil, event_id: nil, status: nil, limit: DEFAULT_LIMIT)
    if query.blank? && event_id.blank?
      return { status: 'error',
               errors: ['Give a query (name, e-mail or verification code) or an event_id. ' \
                        'search_participants does not list every participant.'] }.to_json
    end

    scope = filtered(query, event_id, status)
    participants = scope.limit(limit.clamp(1, MAX_LIMIT)).map { |participant| summary(participant) }
    listing(:participants, participants, total: scope.count, narrow: 'query, event_id or status')
  end

  private

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
end

# frozen_string_literal: true

class IssueCertificateTool < AuthenticatedTool
  tool_name 'issue_certificate'
  requires_permission :update, Participant

  description <<~MD
    Issues one participant's certificate: renders the A4 and LETTER PDFs and
    uploads them to S3, which is what makes the code verifiable at
    kleer.la/certificado — the public page looks for the file, not the record.

    It does not mail anything unless you pass notify=true.

    The participant has to be Presente (A) or Certificado (K), and the event's
    first trainer needs a signature image loaded, or nothing is generated.

    Two steps: confirm=false (the default) checks and describes what it would
    do; call again with confirm=true to actually issue it.
  MD

  arguments do
    required(:participant_id).filled(:integer).description('Participant id, from search_participants')
    optional(:notify).filled(:bool).description('true = also mail the certificate to the participant')
    optional(:confirm).filled(:bool).description('false (default) = check only; true = generate and upload')
  end

  def call(participant_id:, notify: false, confirm: false)
    participant = Participant.find_by(id: participant_id)
    if participant.nil?
      return { status: 'error',
               errors: ["Unknown participant #{participant_id}. Use search_participants to find them."] }.to_json
    end

    CertificateIssueService.new(participant: participant, notify: notify).call(confirm: confirm).to_json
  end
end

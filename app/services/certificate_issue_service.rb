# frozen_string_literal: true

# Issues one participant's certificate: renders the A4 and LETTER PDFs and puts
# them in S3, which is what makes the code verifiable — kleer.la/certificado
# does not read this database, it looks for the file by its verification code.
#
# Mailing it is a separate decision. The admin's bulk action always mails; here
# the default is not to, because generating a link to review is the common case
# and an unexpected mail to a participant cannot be taken back.
class CertificateIssueService
  VERIFY_URL = 'https://kleer.la/certificado'

  def initialize(participant:, notify: false)
    @participant = participant
    @notify = notify
  end

  # Why this participant cannot get a certificate right now, in the order the
  # certificate itself would hit them. Empty means it can be issued.
  def self.blockers(participant)
    [].tap do |list|
      unless participant.could_receive_certificate?
        list << "Status is #{participant.human_status} (#{participant.status}): only Presente (A) or " \
                'Certificado (K) can be certified.'
      end
      if participant.event.trainer&.signature_image.blank?
        list << "The first trainer (#{participant.event.trainer&.name}) has no signature image, so the " \
                'certificate would come out unsigned. Load it from the admin, under Trainers.'
      end
    end
  end

  def call(confirm: false)
    blockers = self.class.blockers(@participant)
    return { status: 'error', errors: blockers } if blockers.any?
    return preview unless confirm

    issue
  end

  private

  def preview
    { status: 'preview', participant: participant_summary,
      will: 'Render the A4 and LETTER PDFs and upload them to S3, making the code verifiable at ' \
            "#{VERIFY_URL}.",
      notify: @notify,
      note: 'Nothing was generated. Call again with confirm=true to issue it.' }
  end

  def issue
    urls = @participant.generate_certificate
    deliver(urls) if @notify

    { status: 'issued', participant: participant_summary,
      verification_code: @participant.verification_code, urls: urls,
      verify_at: "#{VERIFY_URL}?q=#{@participant.verification_code}",
      notified: @notify,
      note: 'The PDFs are in S3; the code can now be checked on the public page.' }
  end

  def deliver(urls)
    EventMailer.send_certificate(@participant, urls['A4'], urls['LETTER']).deliver
  end

  def participant_summary
    { id: @participant.id, name: "#{@participant.fname} #{@participant.lname}", email: @participant.email,
      event: @participant.event.event_type.name, date: @participant.event.date,
      status: @participant.status }
  end
end

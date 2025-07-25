# frozen_string_literal: true

class EventCertificateService
  class Result
    attr_reader :success, :message, :sent_count

    def initialize(success:, message:, sent_count: 0)
      @success = success
      @message = message
      @sent_count = sent_count
    end

    def success?
      @success
    end

    def failure?
      !@success
    end
  end

  def self.send_certificates(event)
    new(event).send_certificates
  end

  def self.send_certificates_with_hr(event, hr_emails:, hr_message: nil)
    new(event).send_certificates_with_hr(hr_emails: hr_emails, hr_message: hr_message)
  end

  def initialize(event)
    @event = event
  end

  def send_certificates
    return failure_result(I18n.t('flash.event.send_certificate.signature_failure')) unless trainer_has_signature?

    sent_count = 0

    @event.participants.each do |participant|
      if participant.could_receive_certificate?
        participant.delay.generate_certificate_and_notify
        sent_count += 1
      end
    end

    success_result(
      I18n.t('flash.event.send_certificate.success') + "Se están enviando #{sent_count} certificados.",
      sent_count
    )
  end

  def send_certificates_with_hr(hr_emails:, hr_message: nil)
    return failure_result(I18n.t('flash.event.send_certificate.signature_failure')) unless trainer_has_signature?

    # Validate HR emails
    parsed_emails = parse_and_validate_emails(hr_emails)
    if parsed_emails[:invalid].any?
      return failure_result("Email addresses inválidas: #{parsed_emails[:invalid].join(', ')}")
    end

    sent_count = 0
    valid_emails = parsed_emails[:valid]
    processed_message = hr_message.present? ? hr_message : nil

    @event.participants.each do |participant|
      next unless participant.could_receive_certificate?

      participant.delay.generate_certificate_and_notify_with_hr(
        hr_emails: valid_emails,
        hr_message: processed_message
      )
      sent_count += 1
    end

    hr_info = valid_emails.any? ? " con copia a: #{valid_emails.join(', ')}" : ''
    success_result("Se están enviando #{sent_count} certificados#{hr_info}.", sent_count)
  end

  private

  def trainer_has_signature?
    @event.trainer.signature_image.present? && @event.trainer.signature_image != ''
  end

  def parse_and_validate_emails(email_string)
    emails = email_string.to_s.split(/[,;\n]/).map(&:strip).reject(&:blank?)
    valid_emails = []
    invalid_emails = []

    emails.each do |email|
      if email.match?(/\A[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i)
        valid_emails << email
      else
        invalid_emails << email
      end
    end

    { valid: valid_emails, invalid: invalid_emails }
  end

  def success_result(message, sent_count = 0)
    Result.new(success: true, message: message, sent_count: sent_count)
  end

  def failure_result(message)
    Result.new(success: false, message: message)
  end
end

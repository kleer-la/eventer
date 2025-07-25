# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventCertificateService do
  let(:trainer) { create(:trainer, signature_image: 'signature.png') }
  let(:event) { create(:event, trainer: trainer) }
  let(:participant1) { create(:participant, event: event, status: 'A') } # Attended
  let(:participant2) { create(:participant, event: event, status: 'K') } # Certified
  let(:participant3) { create(:participant, event: event, status: 'C') } # Confirmed (no certificate)

  before do
    participant1
    participant2
    participant3
    # Mock the delay method
    allow_any_instance_of(Participant).to receive(:delay).and_return(double(
      generate_certificate_and_notify: true,
      generate_certificate_and_notify_with_hr: true
    ))
  end

  describe '.send_certificates' do
    context 'when trainer has signature' do
      it 'sends certificates to eligible participants' do
        result = described_class.send_certificates(event)

        expect(result).to be_success
        expect(result.sent_count).to eq(2) # Only attended and certified participants
        expect(result.message).to include('Se están enviando 2 certificados')
      end
    end

    context 'when trainer has no signature' do
      let(:trainer) { create(:trainer, signature_image: nil) }

      it 'returns failure result' do
        result = described_class.send_certificates(event)

        expect(result).to be_failure
        expect(result.sent_count).to eq(0)
        expect(result.message).to include('El entrenador necesita tener una firma')
      end
    end
  end

  describe '.send_certificates_with_hr' do
    let(:hr_emails) { 'hr@company.com, manager@company.com' }
    let(:hr_message) { 'Custom HR message' }

    context 'when trainer has signature and emails are valid' do
      it 'sends certificates with HR notification' do
        result = described_class.send_certificates_with_hr(
          event,
          hr_emails: hr_emails,
          hr_message: hr_message
        )

        expect(result).to be_success
        expect(result.sent_count).to eq(2)
        expect(result.message).to include('Se están enviando 2 certificados')
        expect(result.message).to include('con copia a: hr@company.com, manager@company.com')
      end

      it 'works without HR message' do
        result = described_class.send_certificates_with_hr(
          event,
          hr_emails: hr_emails
        )

        expect(result).to be_success
      end
    end

    context 'when trainer has no signature' do
      let(:trainer) { create(:trainer, signature_image: '') }

      it 'returns failure result' do
        result = described_class.send_certificates_with_hr(
          event,
          hr_emails: hr_emails,
          hr_message: hr_message
        )

        expect(result).to be_failure
        expect(result.message).to include('El entrenador necesita tener una firma')
      end
    end

    context 'when HR emails are invalid' do
      let(:invalid_emails) { 'invalid-email, another-bad-email' }

      it 'returns failure result with invalid emails' do
        result = described_class.send_certificates_with_hr(
          event,
          hr_emails: invalid_emails
        )

        expect(result).to be_failure
        expect(result.message).to include('Email addresses inválidas')
        expect(result.message).to include('invalid-email')
        expect(result.message).to include('another-bad-email')
      end
    end

    context 'when some emails are valid and some invalid' do
      let(:mixed_emails) { 'valid@company.com, invalid-email, another@company.com' }

      it 'returns failure result' do
        result = described_class.send_certificates_with_hr(
          event,
          hr_emails: mixed_emails
        )

        expect(result).to be_failure
        expect(result.message).to include('invalid-email')
      end
    end

    context 'with different email separators' do
      it 'handles comma separation' do
        result = described_class.send_certificates_with_hr(
          event,
          hr_emails: 'email1@company.com, email2@company.com'
        )
        expect(result).to be_success
      end

      it 'handles semicolon separation' do
        result = described_class.send_certificates_with_hr(
          event,
          hr_emails: 'email1@company.com; email2@company.com'
        )
        expect(result).to be_success
      end

      it 'handles newline separation' do
        result = described_class.send_certificates_with_hr(
          event,
          hr_emails: "email1@company.com\nemail2@company.com"
        )
        expect(result).to be_success
      end
    end
  end

  describe 'Result class' do
    it 'has success? and failure? methods' do
      success_result = EventCertificateService::Result.new(success: true, message: 'Success')
      failure_result = EventCertificateService::Result.new(success: false, message: 'Failure')

      expect(success_result).to be_success
      expect(success_result).not_to be_failure

      expect(failure_result).to be_failure
      expect(failure_result).not_to be_success
    end
  end
end
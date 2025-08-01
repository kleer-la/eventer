# frozen_string_literal: true

require 'rails_helper'

describe ApplicationMailer do
  describe '#contact_us' do
    let(:name) { 'Test User' }
    let(:email) { 'test@example.com' }
    let(:message) { 'Hello, this is a test.' }
    let(:subject_text) { 'ignored' }
    let(:company) { 'ignored' }

    before do
      allow(Setting).to receive(:get).with(:CONTACT_US_MAILTO).and_return('info@kleer.la')
    end

    context 'when context includes /en/' do
      let(:context) { '/some/path' }

      it 'sets locale to :en for subject and body' do
        mail = described_class.contact_us(name, email, company, 'en', context, subject_text, message)
        expect(mail.subject).to eq(I18n.t('mail.contact_us.subject', locale: :en, name: name))
        expect(mail.parts.find do |p|
          p.content_type.match(/html/)
        end.body.encoded).to include(I18n.t('mail.contact_us.body', locale: :en, message:,
                                                                    company:, context:, name:, email:))

        # Normalize line endings for comparison
        plain_body = mail.parts.find { |p| p.content_type.match(/plain/) }.body.encoded.gsub(/\r\n/, "\n")
        expected_text = I18n.t('mail.contact_us.body_text', locale: :en, message:, company:, context:, name:, email:)
        expect(plain_body).to include(expected_text)
      end
    end

    context 'when context does not include /en/' do
      let(:context) { '/algun/camino' }

      it 'sets locale to :es for subject and body' do
        mail = described_class.contact_us(name, email, company, 'es', context, subject_text, message)
        expect(mail.subject).to eq(I18n.t('mail.contact_us.subject', locale: :es, name: name))
        expect(mail.parts.find do |p|
          p.content_type.match(/html/)
        end.body.encoded).to include(I18n.t('mail.contact_us.body', locale: :es, message:,
                                                                    company:, context:, name:, email:))

        # Normalize line endings for comparison
        plain_body = mail.parts.find { |p| p.content_type.match(/plain/) }.body.encoded.gsub(/\r\n/, "\n")
        expected_text = I18n.t('mail.contact_us.body_text', locale: :es, message:, company:, context:, name:, email:)
        expect(plain_body).to include(expected_text)
      end
    end
  end
end

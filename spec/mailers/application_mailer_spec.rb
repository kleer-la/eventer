# frozen_string_literal: true

require 'rails_helper'

describe ApplicationMailer do
  describe '#contact_us' do
    let(:name) { 'Test User' }
    let(:email) { 'test@example.com' }
    let(:message) { 'Hello, this is a test.' }
    let(:subject_text) { 'ignored' }

    before do
      allow(Setting).to receive(:get).with(:CONTACT_US_MAILTO).and_return('info@kleer.la')
    end

    context 'when context includes /en/' do
      let(:context) { '/en/some/path' }

      it 'sets locale to :en for subject and body' do
        mail = described_class.contact_us(name, email, context, subject_text, message)
        expect(mail.subject).to eq(I18n.t('mail.contact_us.subject', locale: :en, name: name))
        expect(mail.body.encoded).to include(I18n.t('mail.contact_us.body', locale: :en, message: message,
                                                                            context: context, name: name, email: email))
      end
    end

    context 'when context does not include /en/' do
      let(:context) { '/es/algun/camino' }

      it 'sets locale to :es for subject and body' do
        mail = described_class.contact_us(name, email, context, subject_text, message)
        expect(mail.subject).to eq(I18n.t('mail.contact_us.subject', locale: :es, name: name))
        expect(mail.body.encoded).to include(I18n.t('mail.contact_us.body', locale: :es, message: message,
                                                                            context: context, name: name, email: email))
      end
    end
  end
end

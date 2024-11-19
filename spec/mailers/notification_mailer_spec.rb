require 'rails_helper'

RSpec.describe NotificationMailer, type: :mailer do
  describe '#custom_notification' do
    let(:contact) { create(:contact, email: 'user@example.com', form_data: { name: 'John' }) }
    let(:template) do
      create(:mail_template,
             subject: 'Welcome {{contact.form_data.name}}',
             content: 'Hello {{name}}!',
             to: '{{contact.email}}',
             cc: 'manager@example.com')
    end
    let(:mail) { NotificationMailer.custom_notification(contact, template) }

    it 'renders the headers' do
      expect(mail.subject).to eq('Welcome John')
      expect(mail.to).to eq(['user@example.com'])
      expect(mail.cc).to eq(['manager@example.com'])
    end

    it 'renders the content' do
      expect(mail.body.encoded).to match('Hello John!')
    end
  end

  describe '#daily_digest' do
    let(:contacts) do
      [
        create(:contact, email: 'user1@example.com', form_data: { name: 'John' }),
        create(:contact, email: 'user2@example.com', form_data: { name: 'Jane' })
      ]
    end
    let(:template) do
      create(:mail_template,
             subject: 'Daily Contacts',
             content: 'We received new contacts',
             to: 'admin@example.com')
    end
    let(:mail) { NotificationMailer.daily_digest(contacts, template) }

    it 'renders the headers' do
      expect(mail.subject).to eq('Daily Contacts')
      expect(mail.to).to eq(['admin@example.com'])
    end

    it 'renders the content' do
      expect(mail.body.encoded).to match('We received new contacts')
    end
  end
end

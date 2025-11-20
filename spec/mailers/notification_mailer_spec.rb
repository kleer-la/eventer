require 'rails_helper'

RSpec.describe NotificationMailer, type: :mailer do
  describe '#custom_notification' do
    let(:contact) { create(:contact, form_data: { email: 'user@example.com', name: 'John' }) }
    let(:template) do
      create(:mail_template,
             subject: 'Welcome {{name}}',
             content: 'Hello {{name}}!',
             to: '{{email}}',
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

    context 'with multiline content in template' do
      let(:template) do
        create(:mail_template,
               subject: 'Welcome {{name}}',
               content: "Line 1\nLine 2\nLine 3",
               to: '{{email}}',
               cc: 'manager@example.com')
      end

      it 'converts newlines to <br> tags in HTML part' do
        html_part = mail.html_part.body.decoded
        expect(html_part).to include("Line 1<br>\nLine 2<br>\nLine 3")
      end

      it 'preserves newlines in text part' do
        text_part = mail.text_part.body.decoded
        expect(text_part).to include("Line 1\nLine 2\nLine 3")
      end
    end

    context 'with multiline content in form data' do
      let(:contact) do
        create(:contact, form_data: {
                 email: 'user@example.com',
                 name: 'John',
                 message: "First line\nSecond line\nThird line"
               })
      end
      let(:template) do
        create(:mail_template,
               subject: 'Contact from {{name}}',
               content: "Name: {{name}}\nMessage:\n{{message}}",
               to: 'admin@example.com')
      end

      it 'converts newlines in interpolated variables to <br> tags in HTML part' do
        html_part = mail.html_part.body.decoded
        expect(html_part).to include('First line<br>')
        expect(html_part).to include('Second line<br>')
        expect(html_part).to include('Third line')
      end

      it 'preserves newlines in text part' do
        text_part = mail.text_part.body.decoded
        expect(text_part).to include("First line\nSecond line\nThird line")
      end
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

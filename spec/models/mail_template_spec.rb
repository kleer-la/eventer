require 'rails_helper'

RSpec.describe MailTemplate, type: :model do
  describe '.for' do
    def template(identifier, lang: 'es', resource_slug: nil, **attrs)
      defaults = { identifier: identifier, trigger_type: 'download_form', lang: lang, resource_slug: resource_slug,
                   active: true, delivery_schedule: 'immediate' }
      create(:mail_template, defaults.merge(attrs))
    end

    def download_of(slug, language: 'es')
      Contact.create!(trigger_type: :download_form, email: 'ana@example.com',
                      form_data: { 'resource_slug' => slug, 'language' => language })
    end

    it 'prefers the templates of the contact resource over the generic ones' do
      generic = template('generic_es')
      own = template('handoff_es', resource_slug: 'session-handoff')
      template('other_es', resource_slug: 'otro-recurso')

      expect(described_class.for(download_of('session-handoff'))).to eq [own]
      expect(described_class.for(download_of('otro-recurso'))).not_to include(generic, own)
      expect(described_class.for(download_of('guia-x'))).to eq [generic]
    end

    it 'respects language, activity and schedule' do
      template('handoff_en', lang: 'en', resource_slug: 'session-handoff')
      template('handoff_es_off', resource_slug: 'session-handoff', active: false)
      template('handoff_es_daily', resource_slug: 'session-handoff', delivery_schedule: 'daily')
      generic = template('generic_es')

      expect(described_class.for(download_of('session-handoff', language: 'en')).map(&:identifier)).to eq ['handoff_en']
      # No immediate, active Spanish template of its own: the generic one applies
      expect(described_class.for(download_of('session-handoff'))).to eq [generic]
    end

    it 'defaults to Spanish when the contact has no language' do
      generic = template('generic_es')
      contact = Contact.create!(trigger_type: :download_form, email: 'a@b.c', form_data: { 'resource_slug' => 'x' })

      expect(described_class.for(contact)).to eq [generic]
    end
  end

  describe 'validations' do
    let(:template) { build(:mail_template) }

    it 'requires trigger_type' do
      template.trigger_type = nil
      expect(template).not_to be_valid
      expect(template.errors[:trigger_type]).to include('no puede estar en blanco')
    end

    it 'requires identifier' do
      template.identifier = nil
      expect(template).not_to be_valid
      expect(template.errors[:identifier]).to include('no puede estar en blanco')
    end

    it 'requires subject' do
      template.subject = nil
      expect(template).not_to be_valid
      expect(template.errors[:subject]).to include('no puede estar en blanco')
    end

    it 'requires content' do
      template.content = nil
      expect(template).not_to be_valid
      expect(template.errors[:content]).to include('no puede estar en blanco')
    end

    it 'requires to' do
      template.to = nil
      expect(template).not_to be_valid
      expect(template.errors[:to]).to include('no puede estar en blanco')
    end

    it 'requires unique identifier' do
      create(:mail_template, identifier: 'welcome')
      template.identifier = 'welcome'
      expect(template).not_to be_valid
      expect(template.errors[:identifier]).to include('ya está en uso')
    end
  end

  describe 'enums' do
    describe 'trigger_type' do
      it 'defines contact_form as 0' do
        expect(MailTemplate.trigger_types[:contact_form]).to eq 0
      end

      it 'defines download_form as 1' do
        expect(MailTemplate.trigger_types[:download_form]).to eq 1
      end

      it 'can be set via symbol' do
        template = MailTemplate.new(trigger_type: :contact_form)
        expect(template.contact_form?).to be true
      end
    end

    describe 'delivery_schedule' do
      it 'defines immediate as 0' do
        expect(MailTemplate.delivery_schedules[:immediate]).to eq 0
      end

      it 'defines daily as 1' do
        expect(MailTemplate.delivery_schedules[:daily]).to eq 1
      end

      it 'can be queried' do
        template = MailTemplate.new(delivery_schedule: :daily)
        expect(template.daily?).to be true
      end
    end
  end

  describe '#render_content' do
    let(:template) { create(:mail_template, content: 'Hello {{name}}!') }
    let(:contact) { create(:contact, form_data: { name: 'John' }) }

    it 'replaces variables in content' do
      expect(template.render_content(contact)).to eq('Hello John!')
    end
  end

  describe '#render_field' do
    let(:contact) do
      create(:contact,
             email: 'john@example.com',
             form_data: {
               'email': 'john@example.com',
               'name' => 'John Doe',
               'message' => 'Test message',
               'resource_title_es' => 'Resource Guide'
             })
    end

    context 'when rendering to field' do
      it 'renders simple template' do
        template = create(:mail_template, to: 'support@example.com')
        expect(template.render_field('to', contact)).to eq('support@example.com')
      end

      it 'renders with contact attributes' do
        template = create(:mail_template, to: '{{email}}')
        expect(template.render_field('to', contact)).to eq('john@example.com')
      end

      it 'renders with form data' do
        template = create(:mail_template, to: '{{name}} <{{email}}>')
        expect(template.render_field('to', contact)).to eq('John Doe <john@example.com>')
      end
    end

    context 'when rendering subject field' do
      it 'renders simple template' do
        template = create(:mail_template, subject: 'Contact Form Submission')
        expect(template.render_field('subject', contact)).to eq('Contact Form Submission')
      end

      it 'renders with form data' do
        template = create(:mail_template, subject: 'Message from {{name}}')
        expect(template.render_field('subject', contact)).to eq('Message from John Doe')
      end

      it 'renders with multiple variables' do
        template = create(:mail_template,
                          subject: 'Download request: {{resource_title_es}} by {{name}}')
        expect(template.render_field('subject', contact))
          .to eq('Download request: Resource Guide by John Doe')
      end
    end

    context 'when rendering cc field' do
      it 'returns nil for blank cc' do
        template = create(:mail_template, cc: nil)
        expect(template.render_field('cc', contact)).to be_nil
      end

      it 'renders empty string' do
        template = create(:mail_template, cc: '')
        expect(template.render_field('cc', contact)).to eq('')
      end

      it 'renders with form data' do
        template = create(:mail_template, cc: 'copy-{{name}}@example.com')
        expect(template.render_field('cc', contact)).to eq('copy-John Doe@example.com')
      end
    end

    context 'with invalid liquid syntax' do
      it 'preserves the template text' do
        template = create(:mail_template, subject: 'Hello {{invalid}')
        expect(template.render_field('subject', contact)).to eq('Hello {{invalid}')
      end
    end

    context 'with non-existent variables' do
      it 'renders empty string for missing values' do
        template = create(:mail_template, subject: 'Value: {{form_data.non_existent}}')
        expect(template.render_field('subject', contact)).to eq('Value: ')
      end
    end

    context 'with complex nested data' do
      let(:contact_with_nested) do
        create(:contact,
               email: 'john@example.com',
               form_data: {
                 'user' => {
                   'name' => 'John Doe',
                   'role' => 'Admin'
                 }
               })
      end

      it 'renders nested form data' do
        template = create(:mail_template, subject: 'New {{user.role}}: {{user.name}}')
        expect(template.render_field('subject', contact_with_nested))
          .to eq('New Admin: John Doe')
      end
    end
  end
end

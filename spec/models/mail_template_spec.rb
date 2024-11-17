require 'rails_helper'

RSpec.describe MailTemplate, type: :model do
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

  # describe '#render_content' do
  #   let(:template) { create(:mail_template, content: 'Hello {{name}}!') }
  #   let(:contact) { create(:contact_record, form_data: { name: 'John' }) }

  #   it 'replaces variables in content' do
  #     expect(template.render_content(contact)).to eq('Hello John!')
  #   end
  # end
end

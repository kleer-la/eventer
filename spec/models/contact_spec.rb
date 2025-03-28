require 'rails_helper'
RSpec.describe Contact, type: :model do
  describe 'validations' do
    let(:contact) { build(:contact) }

    it 'is valid with valid attributes' do
      expect(contact).to be_valid
    end

    it 'requires trigger_type' do
      contact.trigger_type = nil
      expect(contact).not_to be_valid
    end

    it 'requires email' do
      contact.email = nil
      expect(contact).not_to be_valid
    end

    it 'requires form_data' do
      contact.form_data = nil
      expect(contact).not_to be_valid
    end
  end

  describe 'enums' do
    describe 'trigger_type' do
      it 'has the expected values' do
        expect(Contact.trigger_types.keys).to match_array(%w[contact_form download_form assessment_submission])
      end

      it 'can be set and queried' do
        contact = build(:contact, trigger_type: :contact_form)
        expect(contact.contact_form?).to be true
        expect(contact.download_form?).to be false
      end
    end

    describe 'status' do
      it 'has the expected values' do
        expect(Contact.statuses.keys).to match_array(%w[pending in_progress completed failed])
      end

      it 'can be set and queried' do
        contact = build(:contact, status: :pending)
        expect(contact.pending?).to be true
        expect(contact.completed?).to be false
      end
    end
  end

  describe 'scopes' do
    it 'uncompleted returns pending records' do
      pending = create(:contact, status: :pending)
      completed = create(:contact, status: :completed)

      expect(Contact.pending).to include(pending)
      expect(Contact.pending).not_to include(completed)
    end

    it 'last_24h returns recent records' do
      recent = create(:contact, created_at: 1.hour.ago)
      old = create(:contact, created_at: 2.days.ago)

      expect(Contact.last_24h).to include(recent)
      expect(Contact.last_24h).not_to include(old)
    end
  end

  describe 'callbacks' do
    describe 'after_create' do
      it 'updates fields from form_data' do
        form_data = {
          'resource_slug' => 'test-resource',
          'content_updates_opt_in' => '1',
          'newsletter_opt_in' => 'true'
        }

        contact = create(:contact, form_data:)

        expect(contact.resource_slug).to eq('test-resource')
        expect(contact.content_updates_opt_in).to be true
        expect(contact.newsletter_opt_in).to be true
      end

      it 'handles missing form_data fields' do
        form_data = { 'resource_slug' => 'test-resource' }
        contact = create(:contact, form_data:)

        expect(contact.resource_slug).to eq('test-resource')
        expect(contact.content_updates_opt_in).to be false
        expect(contact.newsletter_opt_in).to be false
      end

      it 'converts various truthy values to boolean' do
        form_data = {
          'content_updates_opt_in' => '1',
          'newsletter_opt_in' => 'yes'
        }
        contact = create(:contact, form_data:)

        expect(contact.content_updates_opt_in).to be true
        expect(contact.newsletter_opt_in).to be true
      end

      it 'converts various falsy values to boolean' do
        form_data = {
          content_updates_opt_in: '0',
          newsletter_opt_in: 'false'
        }
        contact = create(:contact, form_data:)

        expect(contact.content_updates_opt_in).to be false
        expect(contact.newsletter_opt_in).to be false
      end
    end
  end

  describe 'assessment submission' do
    let(:assessment) { Assessment.create(title: 'Skills Assessment', description: 'Evaluate skills') }

    it 'belongs to an assessment and stores user info for a submission' do
      contact = assessment.contacts.create(
        trigger_type: :assessment_submission,
        email: 'jane@acme.com',
        form_data: { name: 'Jane', company: 'Acme' }
      )
      expect(contact.persisted?).to be true
      expect(contact.assessment).to eq assessment
      expect(contact.email).to eq 'jane@acme.com'
      expect(contact.form_data['name']).to eq 'Jane'
      expect(contact.form_data['company']).to eq 'Acme'
      expect(contact.trigger_type).to eq 'assessment_submission'
    end
  end
end

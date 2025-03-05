# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::ContactsController, type: :controller do
  before(:each) do
    ActiveJob::Base.queue_adapter = :test
  end

  let(:valid_contact_params) do
    {
      name: 'John Doe',
      email: 'john@example.com',
      company: 'Acme Corp',
      context: '/recursos',
      message: 'Test message',
      language: 'es',
      secret: 'valid_secret',
      initial_slug: 'original-page'
    }
  end

  let(:resource) do
    create(:resource,
           slug: 'agile-fundamentals',
           title_es: 'Agile Fundamentals Guide',
           getit_es: 'Obtén la guía de Fundamentos Ágiles')
  end

  let(:valid_download_params) do
    valid_contact_params.merge({
                                 resource_slug: resource.slug
                               })
  end

  describe 'POST #create' do
    context 'with valid contact us form parameters' do
      let!(:mail_template) do
        create(:mail_template, :for_contacts)
      end
      it 'creates a new contact' do
        expect do
          post :create, params: valid_contact_params
        end.to change(Contact, :count).by(1)
      end

      it 'sets trigger_type as contact_form' do
        post :create, params: valid_contact_params
        expect(Contact.last.trigger_type).to eq('contact_form')
      end

      it 'enqueues notification email' do
        expect do
          post :create, params: valid_contact_params
        end.to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with('NotificationMailer', 'custom_notification', 'deliver_now', anything)
          .on_queue('default')
      end

      it 'saves form data with request information' do
        post :create, params: valid_contact_params

        contact = Contact.last
        expect(contact.email).to eq('john@example.com')
        expect(contact.form_data).to include(
          'name' => 'John Doe',
          'message' => 'Test message',
          'page' => '/recursos'
        )
      end
      it 'saves form data with company information' do
        post :create, params: valid_contact_params

        contact = Contact.last
        expect(contact.email).to eq('john@example.com')
        expect(contact.form_data).to include(
          'name' => 'John Doe',
          'company' => 'Acme Corp',
          'message' => 'Test message',
          'page' => '/recursos'
        )
      end
    end

    context 'with invalid parameters' do
      before do
        allow_any_instance_of(ContactValidator).to receive(:valid?).and_return(false)
        allow_any_instance_of(ContactValidator).to receive(:error).and_return('validation error')
      end

      it 'does not create contact' do
        expect do
          post :create, params: valid_contact_params
        end.not_to change(Contact, :count)
      end

      it 'returns error status' do
        post :create, params: valid_contact_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'logs the error' do
        post :create, params: valid_contact_params
        last_log = Log.last

        expect(last_log.area).to eq('mail')
        expect(last_log.level).to eq('error')
        expect(last_log.message).to eq('Validation failed')

        # Test presence of key parameters in details
        expect(last_log.details).to include('name')
        expect(last_log.details).to include('john@example.com')
        expect(last_log.details).to include('/recursos')
        expect(last_log.details).to include('Test message')
      end
    end

    context 'with valid download request' do
      let!(:mail_template) do
        create(:mail_template, :for_downloads)
      end
      before { resource } # ensure resource exists

      it 'creates a new contact record' do
        expect do
          post :create, params: valid_download_params
        end.to change(Contact, :count).by(1)
      end

      it 'sets trigger_type as download' do
        post :create, params: valid_download_params
        expect(Contact.last.trigger_type).to eq('download_form')
      end

      it 'includes resource information in form_data' do
        post :create, params: valid_download_params

        form_data = Contact.last.form_data
        expect(form_data['resource_title_es']).to eq('Agile Fundamentals Guide')
        expect(form_data['resource_getit_es']).to eq('Obtén la guía de Fundamentos Ágiles')
      end

      it 'sends download notification emails' do
        expect do
          post :create, params: valid_download_params
        end.to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with('NotificationMailer', 'custom_notification', 'deliver_now', anything)
          .on_queue('default')
      end
    end

    context 'with invalid params' do
      it 'returns validation error for missing required fields' do
        post :create, params: { email: 'invalid' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to have_key('error')
      end

      it 'returns error when resource_slug is invalid' do
        post :create, params: valid_contact_params.merge(resource_slug: 'non-existent')
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Resource not found')
      end
    end

    context 'with language-specific templates' do
      let!(:es_template) do
        create(:mail_template, :for_contacts, lang: :es)
      end

      let!(:en_template) do
        create(:mail_template, :for_contacts, lang: :en)
      end

      before do
        allow(NotificationMailer).to receive(:custom_notification).and_return(
          double(deliver_later: true)
        )
      end

      it 'only sends notifications for templates matching contact language' do
        post :create, params: valid_contact_params.merge(
          language: 'es'
        )

        expect(NotificationMailer).to have_received(:custom_notification)
          .with(anything, es_template)
          .once

        expect(NotificationMailer).not_to have_received(:custom_notification)
          .with(anything, en_template)
      end
      it 'only sends notifications for templates matching contact language (en)' do
        post :create, params: valid_contact_params.merge(
          language: 'en'
        )

        expect(NotificationMailer).not_to have_received(:custom_notification)
          .with(anything, es_template)

        expect(NotificationMailer).to have_received(:custom_notification)
          .with(anything, en_template)
          .once
      end
    end

    describe 'multi download fields handling' do
      it 'handles missing can_we_contact and suscribe' do
        post :create, params: valid_contact_params # For controller specs, we use the action symbol

        expect(response).to have_http_status(200)
        contact = Contact.last
        expect(contact).to be_present
        expect(contact.can_we_contact).to be false
        expect(contact.suscribe).to be false
      end

      it 'processes can_we_contact correctly when on' do
        post :create, params: valid_contact_params.merge(can_we_contact: 'on')

        expect(response).to have_http_status(200)
        contact = Contact.last
        expect(contact.can_we_contact).to be true
      end

      it 'processes suscribe correctly when on' do
        post :create, params: valid_contact_params.merge(suscribe: 'on')

        expect(response).to have_http_status(200)
        contact = Contact.last
        expect(contact.suscribe).to be true
      end

      it 'processes can_we_contact correctly when true' do
        post :create, params: valid_contact_params.merge(can_we_contact: 'true')

        expect(response).to have_http_status(200)
        contact = Contact.last
        expect(contact.can_we_contact).to be true
      end

      it 'processes suscribe correctly when true' do
        post :create, params: valid_contact_params.merge(suscribe: 'true')

        expect(response).to have_http_status(200)
        contact = Contact.last
        expect(contact.suscribe).to be true
      end

      context 'when resource download includes initial_slug' do
        let!(:resource) { create(:resource, slug: 'test-resource') }

        it 'maintains initial_slug different from resource_slug' do
          post :create, params: valid_contact_params.merge(
            resource_slug: 'test-resource',
            initial_slug: 'came-from-here'
          )

          expect(response).to have_http_status(200)
          contact = Contact.last
          expect(contact).to be_present
          expect(contact.form_data['initial_slug']).to eq('came-from-here')
          expect(contact.form_data['resource_slug']).to eq('test-resource')
        end
      end
    end
  end
  describe 'error logging' do
    it 'logs contact save errors' do
      contact = Contact.new # Real instance
      allow(contact).to receive(:errors).and_return(double(full_messages: ['Test error message']))
      allow_any_instance_of(Contact).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(contact))

      post :create, params: valid_contact_params

      last_log = Log.last
      expect(last_log.area).to eq('mail')
      expect(last_log.level).to eq('error')
      expect(last_log.message).to eq('Validation failed during processing')
      expect(last_log.details).to include('Test error message')
    end

    it 'logs unexpected errors' do
      allow_any_instance_of(Contact).to receive(:save!).and_raise(StandardError.new('Unexpected error'))

      post :create, params: valid_contact_params

      expect(response).to have_http_status(500)
      last_log = Log.last
      expect(last_log.area).to eq('mail')
      expect(last_log.level).to eq('error')
      expect(last_log.message).to eq('Unexpected error')
      expect(last_log.details).to include('Unexpected error')
      expect(last_log.details).to include('backtrace')
    end
  end
  describe 'an assessment' do
    let(:question) { create(:question, id: 1) }
    let(:answer) { create(:answer, id: 5) }
    let(:assessment) { create(:assessment) }
    let(:assessment_resources) { create(:resource, slug: 'un-assessment', title_es: 'Un Assessment', assessment:) }
    let(:valid_assessment_params) do
      valid_contact_params.merge({ resource_slug: 'un-assessment',
                                   resource_title_es: 'Un Assessment',
                                   assessment_id: assessment.id.to_s,
                                   assessment_results: '{"1":"5"}' })
    end
    let(:contact) { Contact.last }

    before do
      question
      answer
      assessment_resources
    end

    it 'creates a new contact with the correct form data' do
      post :create, params: valid_assessment_params

      expect(response).to have_http_status(:ok)
      expect(contact.form_data).to include(
        'name' => 'John Doe',
        'email' => 'john@example.com',
        'company' => 'Acme Corp',
        'page' => '/recursos',
        'language' => 'es',
        'resource_title_es' => 'Un Assessment',
        'resource_slug' => 'un-assessment',
        'assessment_id' => assessment.id.to_s,
        'assessment_results' => '{"1":"5"}'
      )
    end
    it 'creates responses for assessment results' do
      post :create, params: valid_assessment_params

      expect(response).to have_http_status(:ok)
      expect(contact.responses.count).to eq(1)
      expect(contact.responses.pluck(:question_id, :answer_id)).to contain_exactly(
        [1, 5]
      )
    end
  end
end

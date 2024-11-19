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
      message: 'Test message',
      context: '/recursos',
      secret: 'valid_secret'
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
        expect(Log).to receive(:log).with(:mail, :info, 'Validation failed', 'validation error')
        post :create, params: valid_contact_params
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
  end
end

# spec/controllers/api/contacts_controller_spec.rb
require 'rails_helper'

RSpec.describe Api::ContactsController, type: :controller do
  before(:each) do
    ActiveJob::Base.queue_adapter = :test
  end
  describe 'POST #create' do
    let(:valid_params) do
      {
        name: 'Papa',
        email: 'test@example.com',
        context: '/services',
        message: 'Hello there'
      }
    end

    let!(:mail_template) do
      create(:mail_template,
             trigger_type: 'contact_form',
             delivery_schedule: 'immediate',
             active: true)
    end

    context 'with valid parameters' do
      before do
        allow_any_instance_of(ContactValidator).to receive(:valid?).and_return(true)
      end

      it 'creates a new contact' do
        expect do
          post :create, params: valid_params
        end.to change(Contact, :count).by(1)
      end

      it 'enqueues notification email' do
        expect do
          post :create, params: valid_params
        end.to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with('NotificationMailer', 'custom_notification', 'deliver_now', anything)
          .on_queue('default')
      end

      it 'saves form data with request information' do
        request.env['HTTP_USER_AGENT'] = 'TestBrowser'
        request.env['REMOTE_ADDR'] = '1.2.3.4'

        post :create, params: valid_params

        contact = Contact.last
        expect(contact.email).to eq('test@example.com')
        expect(contact.form_data).to include(
          'name' => 'Papa',
          'message' => 'Hello there',
          'page' => '/services',
          'user_agent' => 'TestBrowser',
          'ip' => '1.2.3.4'
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
          post :create, params: valid_params
        end.not_to change(Contact, :count)
      end

      it 'returns error status' do
        post :create, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'logs the error' do
        expect(Log).to receive(:log).with(:mail, :info, 'Validation failed', 'validation error')
        post :create, params: valid_params
      end
    end
  end
end

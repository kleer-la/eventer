# spec/requests/api/contacts_webhook_spec.rb
require 'rails_helper'

RSpec.describe 'Api::Contacts Webhook Integration', type: :request do
  let(:webhook_url) { 'http://fake-webhook-target.com' }
  let(:resource) { create(:resource, slug: 'test-resource') }
  let(:contact_params) do
    {
      name: 'Test User',
      email: 'test@example.com',
      company: 'Test Inc',
      resource_slug: resource.slug,
      language: 'en',
      content_updates_opt_in: 'true',
      newsletter_opt_in: 'true',
      context: '/some/path',
      secret: ENV['CONTACT_US_SECRET']
    }
  end

  before do
    stub_request(:post, webhook_url).to_return(status: 200, body: '')
    create(:webhook, url: webhook_url, event: 'contact.created', active: true) # Create a Webhook record
  end

  it 'triggers a webhook when a contact is created for a resource download' do
    post '/api/contacts', params: contact_params

    expect(response).to have_http_status(:created)
    contact = Contact.last
    expect(JSON.parse(response.body)).to include(
      'id' => contact.id,
      'name' => 'Test User',
      'company' => 'Test Inc',
      'status' => contact.status
    )

    Delayed::Worker.new.work_off

    expect(a_request(:post, webhook_url)
      .with(
        body: {
          contact: {
            id: contact.id,
            name: 'Test User',
            email: 'test@example.com',
            company: 'Test Inc',
            resource_slug: 'test-resource',
            trigger_type: 'download_form'
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      ))
      .to have_been_made.once
  end

  it 'does not trigger webhook if validation fails' do
    allow(ContactValidator).to receive(:new).and_return(instance_double(ContactValidator, valid?: false,
                                                                                          error: 'Invalid email'))
    post '/api/contacts', params: contact_params

    expect(response).to have_http_status(422)
    expect(JSON.parse(response.body)).to eq({ 'error' => 'Invalid email' })

    Delayed::Worker.new.work_off
    expect(a_request(:post, webhook_url)).not_to have_been_made
  end

  it 'still creates contact if webhook fails' do
    stub_request(:post, webhook_url).to_return(status: 500)
    post '/api/contacts', params: contact_params

    expect(response).to have_http_status(:created)
    expect(Contact.exists?(email: 'test@example.com')).to be true
    Delayed::Worker.new.work_off
    expect(a_request(:post, webhook_url)).to have_been_made
  end

  it 'returns error if resource not found' do
    post '/api/contacts', params: contact_params.merge(resource_slug: 'invalid')
    expect(response).to have_http_status(422)
    expect(JSON.parse(response.body)).to eq({ 'error' => 'Resource not found' })
    Delayed::Worker.new.work_off
    expect(a_request(:post, webhook_url)).not_to have_been_made
  end
end

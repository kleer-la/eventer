# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V3::ParticipantsController', type: :request do  
  let!(:event_type) { create(:event_type, name: 'Test Course') }
  let!(:event) { create(:event, event_type: event_type, list_price: 100.0) }
  let!(:influence_zone) { create(:influence_zone) }

  describe 'POST /api/v3/events/:event_id/participants/register' do
    let(:valid_params) do
      {
        fname: 'John',
        lname: 'Doe', 
        email: 'john@example.com',
        phone: '123456789',
        company_name: 'Test Company',
        address: '123 Test St',
        quantity: 1,
        notes: 'Test registration',
        accept_terms: '1',
        recaptcha_token: 'test_token'
      }
    end

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('RECAPTCHA_SITE_KEY').and_return('test_key')
    end

    context 'with valid parameters' do
      it 'creates a new participant' do
        expect {
          post "/api/v3/events/#{event.id}/participants/register", params: valid_params
        }.to change(Participant, :count).by(1)
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to be_present
        expect(json_response['status']).to eq('T') # Status code for 'contacted'
        expect(json_response['free']).to be false
      end
    end

    context 'with invalid event' do
      it 'returns error for non-existent event' do
        post '/api/v3/events/99999/participants/register', params: valid_params
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Event not found')
      end
    end

    context 'with cancelled event' do
      before { event.update(cancelled: true) }

      it 'returns error for cancelled event' do
        post "/api/v3/events/#{event.id}/participants/register", params: valid_params
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Event is cancelled or draft')
      end
    end
  end

  describe 'GET /api/v3/events/:event_id/participants/pricing_info' do
    it 'returns pricing information' do
      get "/api/v3/events/#{event.id}/participants/pricing_info", params: { quantity: 2 }
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['quantity']).to eq(2)
      expect(json_response['unit_price']).to be_present
      expect(json_response['total_price']).to be_present
    end
  end
end
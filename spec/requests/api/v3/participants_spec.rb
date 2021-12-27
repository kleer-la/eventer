# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V3::Participants', type: :request do
  describe 'POST /interest' do
    context 'with event' do
      before(:example) do
        @event = FactoryBot.create(:event)
        iz = FactoryBot.create(:influence_zone, country: Country.find_by(iso_code: 'AR'))
      end
      it 'returns http success' do
        post '/api/v3/participants/interest'
        expect(response).to have_http_status(:success)
      end
      it 'add to an event' do
        request_body = {
          event_id: @event.id,
          event_type_id: 0,
          firstname: 'New',
          lastname: 'Participant',
          country_iso: 'AR',
          email: 'new@gmail.com',
          notes: 'New comment'
        }
        expect do
          post('/api/v3/participants/interest', params: request_body)
        end.to change(Participant, :count).by(1)

        expect(response).to have_http_status(:success)
      end

      it 'fail to add to an event (missing attributes)' do
        request_body = {
          event_id: @event.id,
          event_type_id: 0,
          firstname: '',
          lastname: '',
          country_iso: 'AR',
          email: '',
          notes: 'New comment'
        }
        expect do
          post('/api/v3/participants/interest', params: request_body)
        end.to change(Participant, :count).by(0)

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to match(/Fname/)
        expect(response.body).to match(/Lname/)
        expect(response.body).to match(/Email/)
      end
      it 'add to an event type' do
        request_body = {
          event_id: 0,
          event_type_id: @event.event_type_id,
          firstname: 'New',
          lastname: 'Participant',
          country_iso: 'AR',
          email: 'new@gmail.com',
          notes: 'New comment'
        }
        expect do
          post('/api/v3/participants/interest', params: request_body)
        end.to change(Participant, :count).by(1)

        expect(response).to have_http_status(:success)
      end
    end

    context 'just event type' do
      before(:example) do
        @event_type = FactoryBot.create(:event_type)
        # iz= FactoryBot.create(:influence_zone, country: Country.find_by(iso_code: 'AR'))
      end

      it 'interested in an event type -> no participant added' do
        request_body = {
          event_id: 0,
          event_type_id: @event_type.id,
          firstname: 'New',
          lastname: 'Participant',
          country_iso: 'AR',
          email: 'new@gmail.com',
          notes: 'New comment'
        }
        expect do
          post('/api/v3/participants/interest', params: request_body)
        end.to change(Participant, :count).by(0)

        expect(response).to have_http_status(:success)
      end
    end
  end
end

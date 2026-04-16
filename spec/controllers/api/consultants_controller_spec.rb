# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::ConsultantsController, type: :controller do
  before do
    stub_request(:get, 'https://www.googleapis.com/calendar/v3/users/me/calendarList')
      .to_return(
        status: 200,
        body: { items: [{ id: 'primary' }] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  describe 'GET #index (consultants for service area)' do
    let(:service_area) { FactoryBot.create(:service_area, visible: true) }

    it 'returns booking_enabled active trainers for the service area' do
      bookable = FactoryBot.create(:trainer, name: 'Bookable Trainer', booking_enabled: true)
      not_bookable = FactoryBot.create(:trainer, name: 'Not Bookable', booking_enabled: false)
      service_area.trainers << [bookable, not_bookable]

      get :index, params: { slug: service_area.slug }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first['name']).to eq('Bookable Trainer')
    end

    it 'excludes deleted trainers' do
      deleted = FactoryBot.create(:trainer, name: 'Deleted', booking_enabled: true, deleted: true)
      service_area.trainers << deleted

      get :index, params: { slug: service_area.slug }

      json = JSON.parse(response.body)
      expect(json).to be_empty
    end

    it 'returns 404 for unknown slug' do
      get :index, params: { slug: 'nonexistent-area' }

      expect(response).to have_http_status(:not_found)
    end

    it 'returns empty array when no bookable trainers' do
      get :index, params: { slug: service_area.slug }

      json = JSON.parse(response.body)
      expect(json).to eq([])
    end

    it 'returns expected JSON fields' do
      trainer = FactoryBot.create(:trainer,
                                  name: 'Test Trainer',
                                  bio: 'Bio text',
                                  bio_en: 'Bio english',
                                  gravatar_email: 'test@example.com',
                                  signature_credentials: 'Agile Coach',
                                  linkedin_url: 'https://linkedin.com/in/test',
                                  booking_enabled: true)
      service_area.trainers << trainer

      get :index, params: { slug: service_area.slug }

      json = JSON.parse(response.body).first
      expect(json.keys).to include('id', 'name', 'bio', 'bio_en', 'gravatar_email',
                                   'signature_credentials', 'linkedin_url')
    end
  end

  describe 'GET #availability' do
    let(:trainer) do
      FactoryBot.create(:trainer,
                        booking_enabled: true,
                        google_access_token: 'token',
                        google_refresh_token: 'refresh',
                        google_token_expires_at: 1.hour.from_now,
                        google_calendar_connected: true)
    end

    before do
      stub_request(:post, 'https://www.googleapis.com/calendar/v3/freeBusy')
        .to_return(
          status: 200,
          body: { calendars: { 'primary' => { busy: [] } } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns available slots' do
      get :availability, params: {
        id: trainer.id,
        start: '2026-04-20',
        end: '2026-04-20',
        timezone: 'America/Argentina/Buenos_Aires'
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['consultant_id']).to eq(trainer.id)
      expect(json['available_slots']).to be_an(Array)
      expect(json['available_slots']).not_to be_empty
    end

    it 'returns 400 when start/end params are missing' do
      get :availability, params: { id: trainer.id }

      expect(response).to have_http_status(:bad_request)
    end

    it 'returns 404 for non-existent trainer' do
      get :availability, params: { id: 999999, start: '2026-04-20', end: '2026-04-20' }

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for trainer without booking_enabled' do
      trainer.update!(booking_enabled: false)

      get :availability, params: { id: trainer.id, start: '2026-04-20', end: '2026-04-20' }

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 422 when range exceeds 14 days' do
      get :availability, params: {
        id: trainer.id,
        start: '2026-04-20',
        end: '2026-05-20'
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST #create_booking' do
    let(:trainer) do
      FactoryBot.create(:trainer,
                        name: 'Consultant',
                        booking_enabled: true,
                        google_access_token: 'token',
                        google_refresh_token: 'refresh',
                        google_token_expires_at: 1.hour.from_now,
                        google_calendar_connected: true)
    end

    let(:valid_params) do
      {
        id: trainer.id,
        secret: ENV['CONTACT_US_SECRET'],
        visitor_name: 'María García',
        visitor_email: 'maria@example.com',
        visitor_company: 'Acme Corp',
        start: '2026-04-20T10:00:00-03:00',
        end: '2026-04-20T10:30:00-03:00',
        notes: 'Interested in agile coaching'
      }
    end

    before do
      # Stub FreeBusy to return no busy periods (slot is available)
      stub_request(:post, 'https://www.googleapis.com/calendar/v3/freeBusy')
        .to_return(
          status: 200,
          body: { calendars: { 'primary' => { busy: [] } } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      # Stub event creation
      stub_request(:post, %r{https://www.googleapis.com/calendar/v3/calendars/.*/events})
        .to_return(
          status: 200,
          body: {
            id: 'google-event-456',
            hangoutLink: 'https://meet.google.com/xyz-abcd-efg'
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'creates a booking and returns 201' do
      expect {
        post :create_booking, params: valid_params
      }.to change(Booking, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['status']).to eq('confirmed')
      expect(json['consultant_name']).to eq('Consultant')
      expect(json['google_meet_link']).to eq('https://meet.google.com/xyz-abcd-efg')
    end

    it 'stores the google_event_id on the booking' do
      post :create_booking, params: valid_params

      booking = Booking.last
      expect(booking.google_event_id).to eq('google-event-456')
    end

    it 'returns 422 on bad secret' do
      post :create_booking, params: valid_params.merge(secret: 'wrong-secret')

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Booking.count).to eq(0)
    end

    it 'returns 404 for non-existent trainer' do
      post :create_booking, params: valid_params.merge(id: 999999)

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 422 when slot is no longer available' do
      # Override FreeBusy to show busy
      stub_request(:post, 'https://www.googleapis.com/calendar/v3/freeBusy')
        .to_return(
          status: 200,
          body: {
            calendars: {
              'primary' => {
                busy: [{ start: '2026-04-20T13:00:00Z', end: '2026-04-20T13:30:00Z' }]
              }
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      post :create_booking, params: valid_params

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['error']).to include('no longer available')
    end

    it 'returns 422 when required fields are missing' do
      post :create_booking, params: valid_params.except(:visitor_name)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'stores qualifying_answers as JSON' do
      answers = { 'goal' => 'improve agile practices', 'team_size' => '10' }
      post :create_booking, params: valid_params.merge(qualifying_answers: answers)

      booking = Booking.last
      expect(booking.qualifying_answers).to eq(answers)
    end
  end
end

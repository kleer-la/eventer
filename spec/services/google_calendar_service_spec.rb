# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GoogleCalendarService do
  let(:trainer) do
    FactoryBot.create(:trainer,
                      google_access_token: 'valid-access-token',
                      google_refresh_token: 'valid-refresh-token',
                      google_token_expires_at: 1.hour.from_now,
                      google_calendar_connected: true,
                      booking_enabled: true)
  end

  let(:service) { described_class.new(trainer) }

  describe '#refresh_token_if_needed!' do
    context 'when token is still fresh' do
      it 'does not call Google token endpoint' do
        service.refresh_token_if_needed!
        # No HTTP calls expected — WebMock will raise if any unstubbed request is made
      end
    end

    context 'when token is expired' do
      before do
        trainer.update!(google_token_expires_at: 1.minute.ago)
        stub_request(:post, 'https://oauth2.googleapis.com/token')
          .with(body: hash_including(
            'grant_type' => 'refresh_token',
            'refresh_token' => 'valid-refresh-token'
          ))
          .to_return(
            status: 200,
            body: {
              access_token: 'new-access-token',
              expires_in: 3600
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'refreshes the token and updates the trainer' do
        service.refresh_token_if_needed!
        trainer.reload
        expect(trainer.google_access_token).to eq('new-access-token')
        expect(trainer.google_token_expires_at).to be > Time.current
      end
    end

    context 'when token refresh fails' do
      before do
        trainer.update!(google_token_expires_at: 1.minute.ago)
        stub_request(:post, 'https://oauth2.googleapis.com/token')
          .to_return(status: 401, body: { error: 'invalid_grant' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns a failure result' do
        result = service.refresh_token_if_needed!
        expect(result).to be_failure
      end
    end
  end

  describe '#fetch_freebusy' do
    let(:start_time) { Time.new(2026, 4, 20, 9, 0, 0, '+00:00') }
    let(:end_time) { Time.new(2026, 4, 20, 18, 0, 0, '+00:00') }

    before do
      stub_request(:post, 'https://www.googleapis.com/calendar/v3/freeBusy')
        .to_return(
          status: 200,
          body: {
            calendars: {
              'primary' => {
                busy: [
                  { start: '2026-04-20T10:00:00Z', end: '2026-04-20T11:00:00Z' },
                  { start: '2026-04-20T14:00:00Z', end: '2026-04-20T14:30:00Z' }
                ]
              }
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns busy periods from primary calendar' do
      result = service.fetch_freebusy(start_time, end_time)
      expect(result).to be_success
      expect(result.data[:busy_periods].length).to eq(2)
    end
  end

  describe '#create_event' do
    let(:booking) do
      FactoryBot.build(:booking,
                       trainer: trainer,
                       visitor_name: 'Test Visitor',
                       visitor_email: 'visitor@example.com',
                       starts_at: Time.new(2026, 4, 20, 10, 0, 0, '+00:00'),
                       ends_at: Time.new(2026, 4, 20, 10, 30, 0, '+00:00'))
    end

    before do
      stub_request(:post, %r{https://www.googleapis.com/calendar/v3/calendars/.*/events})
        .to_return(
          status: 200,
          body: {
            id: 'google-event-123',
            hangoutLink: 'https://meet.google.com/abc-defg-hij'
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'creates a Google Calendar event and returns event details' do
      result = service.create_event(booking)
      expect(result).to be_success
      expect(result.data[:google_event_id]).to eq('google-event-123')
      expect(result.data[:google_meet_link]).to eq('https://meet.google.com/abc-defg-hij')
    end
  end

  describe '#compute_available_slots' do
    let(:monday) { Date.new(2026, 4, 20) } # A Monday
    let(:timezone) { 'America/Argentina/Buenos_Aires' }

    before do
      stub_request(:post, 'https://www.googleapis.com/calendar/v3/freeBusy')
        .to_return(
          status: 200,
          body: {
            calendars: {
              'primary' => {
                busy: [
                  { start: '2026-04-20T13:00:00Z', end: '2026-04-20T14:00:00Z' }
                ]
              }
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns 30-minute slots on weekdays between 9-18h' do
      result = service.compute_available_slots(monday, monday, timezone)
      expect(result).to be_success
      slots = result.data[:available_slots]
      expect(slots).to be_an(Array)
      expect(slots).not_to be_empty

      # All slots should be 30 minutes
      slots.each do |slot|
        expect(slot[:end] - slot[:start]).to eq(30.minutes)
      end
    end

    it 'excludes slots that overlap with busy periods' do
      result = service.compute_available_slots(monday, monday, timezone)
      slots = result.data[:available_slots]
      busy_start = Time.parse('2026-04-20T13:00:00Z')
      busy_end = Time.parse('2026-04-20T14:00:00Z')

      overlapping = slots.select { |s| s[:start] < busy_end && s[:end] > busy_start }
      expect(overlapping).to be_empty
    end

    it 'excludes weekends' do
      saturday = Date.new(2026, 4, 25) # Saturday
      sunday = Date.new(2026, 4, 26)   # Sunday

      stub_request(:post, 'https://www.googleapis.com/calendar/v3/freeBusy')
        .to_return(
          status: 200,
          body: { calendars: { 'primary' => { busy: [] } } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = service.compute_available_slots(saturday, sunday, timezone)
      expect(result).to be_success
      expect(result.data[:available_slots]).to be_empty
    end

    it 'resolves deprecated IANA timezone aliases' do
      result = service.compute_available_slots(monday, monday, 'America/Buenos_Aires')
      expect(result).to be_success
      slots = result.data[:available_slots]

      # Slots should be in Argentina time (UTC-3), starting at 9:00 local = 12:00 UTC
      first_slot = slots.first
      expect(first_slot[:start].utc.hour).to eq(12)
    end

    it 'generates slots in the requested timezone, not UTC' do
      result = service.compute_available_slots(monday, monday, timezone)
      expect(result).to be_success
      slots = result.data[:available_slots]

      # Argentina is UTC-3, so 9:00 local = 12:00 UTC
      expect(slots.first[:start].utc.hour).to eq(12)
      # Last slot starts at 17:30 local = 20:30 UTC
      expect(slots.last[:start].utc.hour).to eq(20)
    end

    it 'falls back to UTC for completely unknown timezones' do
      result = service.compute_available_slots(monday, monday, 'Invalid/Timezone')
      expect(result).to be_success
      slots = result.data[:available_slots]

      # UTC: first slot at 9:00 UTC
      expect(slots.first[:start].utc.hour).to eq(9)
    end

    it 'caps the range at MAX_DAYS_AHEAD' do
      far_end = monday + 30.days

      result = service.compute_available_slots(monday, far_end, timezone)
      expect(result).to be_success
      slots = result.data[:available_slots]

      max_date = (monday + GoogleCalendarService::MAX_DAYS_AHEAD.days)
      slots.each do |slot|
        expect(slot[:start].to_date).to be <= max_date
      end
    end
  end
end

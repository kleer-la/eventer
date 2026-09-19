# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::TtsController, type: :controller do
  let(:secret) { 'the-shared-secret' }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('TTS_API_SECRET').and_return(secret)
  end

  def authorize!(token = secret)
    request.headers['Authorization'] = "Bearer #{token}"
  end

  describe 'POST #create' do
    it 'rejects a request with no bearer token' do
      post :create, params: { beats: [{ narration: 'Hola' }] }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects a request with the wrong token' do
      authorize!('not-the-secret')
      post :create, params: { beats: [{ narration: 'Hola' }] }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects a request with no beats' do
      authorize!
      post :create, params: {}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to be_present
    end

    context 'with a valid request' do
      before do
        authorize!
        allow(TtsBriefingService).to receive(:call).and_return('fake mp3 bytes')
      end

      it 'streams back the synthesized mp3' do
        post :create, params: { beats: [{ narration: 'Hola', duration: 5 }], voice: 'en-US-JennyNeural' }

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq 'audio/mpeg'
        expect(response.body).to eq 'fake mp3 bytes'
      end

      it 'passes the beats and voice through to the service' do
        post :create, params: { beats: [{ narration: 'Hola', duration: 5 }], voice: 'en-US-JennyNeural' }

        expect(TtsBriefingService).to have_received(:call) do |beats:, voice:, rate:|
          expect(beats.size).to eq 1
          expect(beats.first['narration']).to eq 'Hola'
          expect(beats.first['duration'].to_i).to eq 5
          expect(voice).to eq 'en-US-JennyNeural'
          expect(rate).to be_nil
        end
      end
    end

    context 'when the service rejects the input' do
      before do
        authorize!
        allow(TtsBriefingService).to receive(:call).and_raise(TtsBriefingService::Error, 'narration too long')
      end

      it 'answers 422 with the error message' do
        post :create, params: { beats: [{ narration: 'Hola' }] }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq 'narration too long'
      end
    end

    context 'when usage is controlled' do
      before do
        authorize!
        allow(TtsBriefingService).to receive(:call).and_return('fake mp3 bytes')
      end

      it 'records the usage of a successful briefing, never its content' do
        post :create, params: { beats: [{ narration: 'Hola equipo' }, { narration: 'Chau' }] }

        usage = TtsUsage.last
        expect(usage).to have_attributes(status: 'ok', beats_count: 2, chars: 15)
        expect(usage.synthesis_ms).to be >= 0
        expect(usage.attributes.values.map(&:to_s).join).not_to include('Hola equipo')
      end

      it 'records a failed synthesis as an error' do
        allow(TtsBriefingService).to receive(:call).and_raise(TtsBriefingService::Error, 'boom')

        post :create, params: { beats: [{ narration: 'Hola' }] }

        expect(TtsUsage.last.status).to eq 'error'
      end

      it 'records a timed out synthesis as an error' do
        allow(TtsBriefingService).to receive(:call).and_raise(Timeout::Error)

        post :create, params: { beats: [{ narration: 'Hola' }] }

        expect(TtsUsage.last.status).to eq 'error'
      end

      it 'answers 429 with Retry-After once the hourly limit is reached' do
        Setting.create!(key: 'TTS_MAX_BRIEFINGS_PER_HOUR', value: '1')
        TtsUsage.create!(status: 'ok', beats_count: 1, chars: 10, created_at: 20.minutes.ago)

        post :create, params: { beats: [{ narration: 'Hola' }] }

        expect(response).to have_http_status(:too_many_requests)
        expect(response.headers['Retry-After'].to_i).to be_positive
        expect(TtsBriefingService).not_to have_received(:call)
      end

      it 'answers 503 when the kill switch is off' do
        Setting.create!(key: 'TTS_ENABLED', value: 'false')

        post :create, params: { beats: [{ narration: 'Hola' }] }

        expect(response).to have_http_status(:service_unavailable)
        expect(TtsBriefingService).not_to have_received(:call)
      end

      it 'answers 503 with Retry-After when the concurrency cap is reached' do
        Setting.create!(key: 'TTS_MAX_CONCURRENCY', value: '1')
        TtsUsage.create!(status: 'running', beats_count: 1, chars: 10)

        post :create, params: { beats: [{ narration: 'Hola' }] }

        expect(response).to have_http_status(:service_unavailable)
        expect(response.headers['Retry-After']).to be_present
      end

      it 'attributes the usage to a hash of the client IP, not the IP itself' do
        request.remote_addr = '203.0.113.7'

        post :create, params: { beats: [{ narration: 'Hola' }] }

        expect(TtsUsage.last.client_hash).to eq TtsUsage.client_hash_for('203.0.113.7')
        expect(TtsUsage.last.client_hash).not_to include('203')
      end

      it 'logs a denial, with the status and the client, so abuse is visible' do
        Setting.create!(key: 'TTS_ENABLED', value: 'false')
        allow(Rails.logger).to receive(:warn)

        post :create, params: { beats: [{ narration: 'Hola' }] }

        expect(Rails.logger).to have_received(:warn).with(a_string_matching(/TTS briefing denied \(503\).*client/))
      end

      it 'does not record anything for an unauthorized request' do
        request.headers['Authorization'] = 'Bearer nope'

        post :create, params: { beats: [{ narration: 'Hola' }] }

        expect(TtsUsage.count).to eq 0
      end

      it 'does not record anything for a request with no beats' do
        post :create, params: {}

        expect(TtsUsage.count).to eq 0
      end
    end

    context 'with a personal token' do
      let(:user) { create(:handoff_user) }
      let(:token) { HandoffToken.issue!(user) }

      before { allow(TtsBriefingService).to receive(:call).and_return('fake mp3 bytes') }

      it 'authenticates and attributes the usage to the token owner' do
        authorize!(token.plaintext)

        post :create, params: { beats: [{ narration: 'Hola' }] }

        expect(response).to have_http_status(:ok)
        expect(TtsUsage.last.owner_id).to eq user.id
      end

      it 'rejects a revoked token' do
        token.revoke!
        authorize!(token.plaintext)

        post :create, params: { beats: [{ narration: 'Hola' }] }

        expect(response).to have_http_status(:unauthorized)
        expect(TtsUsage.count).to eq 0
      end

      it 'answers 429 once the monthly quota is used' do
        Setting.create!(key: 'TTS_MAX_BRIEFINGS_PER_MONTH_PER_USER', value: '1')
        TtsUsage.create!(status: 'ok', beats_count: 1, chars: 1, owner_id: user.id)
        authorize!(token.plaintext)

        post :create, params: { beats: [{ narration: 'Hola' }] }

        expect(response).to have_http_status(:too_many_requests)
        expect(response.headers['Retry-After'].to_i).to be_positive
      end

      it 'leaves the shared secret working with no owner' do
        authorize!

        post :create, params: { beats: [{ narration: 'Hola' }] }

        expect(response).to have_http_status(:ok)
        expect(TtsUsage.last.owner_id).to be_nil
      end
    end

    context 'when synthesis takes too long' do
      before do
        authorize!
        allow(TtsBriefingService).to receive(:call).and_raise(Timeout::Error)
      end

      it 'answers 504' do
        post :create, params: { beats: [{ narration: 'Hola' }] }

        expect(response).to have_http_status(:gateway_timeout)
      end
    end
  end
end

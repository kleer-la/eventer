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

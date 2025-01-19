# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/api/resources', type: :request do
  describe 'GET /index' do
    it 'has title_es json' do
      create(:resource, title_es: 'some text')

      get '/api/resources', params: { format: :json }

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')

      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
      expect(json).not_to be_empty
      expect(json.first['title_es']).to eq('some text')
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/api/resources', type: :request do
  describe 'GET /index' do
    it 'has title_es json ' do
      FactoryBot.create(:resource, title_es: 'some text')
      get '/api/resources', params: { format: 'json' }

      json = @response.parsed_body
      expect(response).to be_successful
      expect(json[0]['title_es']).to eq 'some text'
    end
  end

end

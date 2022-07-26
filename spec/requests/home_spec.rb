# frozen_string_literal: true

require 'rails_helper'

describe 'GET catalog', type: :request do
  include Rack::Test::Methods
  def app
    Rack::Builder.parse_file('config.ru').first
  end
  pending 'no event one event_type' do
    event_type = FactoryBot.create(:event_type)
    get '/api/catalog', params: { format: 'json' }

    expect(response).to have_http_status(:success)
    
    # json = JSON.parse(last_response.body)
    # expect(json.size).to eq 10
  end
end

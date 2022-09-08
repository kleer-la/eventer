# frozen_string_literal: true

require 'rails_helper'

describe 'GET catalog', type: :request do
  before(:all) do
    Event.all.each {|e| e.destroy}
  end

  it 'no event one event_type' do
    event_type = FactoryBot.create(:event_type, include_in_catalog: true)
    get '/api/catalog', params: { format: 'json' }

    expect(response).to have_http_status(:success)
    
    json = JSON.parse(response.body)
    expect(json.size).to eq 1
  end
  it 'one event one event_type in catalog' do
    event = FactoryBot.create(:event)

    get '/api/catalog', params: { format: 'json' }

    expect(response).to have_http_status(:success)
    json = JSON.parse(response.body)
    expect(json.size).to eq 1
  end
  it 'one event + other event_type in catalog' do
    event = FactoryBot.create(:event)
    event_type = FactoryBot.create(:event_type, include_in_catalog: true)
 
    get '/api/catalog', params: { format: 'json' }

    expect(response).to have_http_status(:success)
    json = JSON.parse(response.body)
    expect(json.size).to eq 2
    expect(json[0]['event_type_id']).not_to eq json[1]['event_type_id']
  end
  it 'one event & w/ event_type in catalog' do
    event = FactoryBot.create(:event)
    event.event_type.include_in_catalog = true
 
    event.event_type.save!

    get '/api/catalog', params: { format: 'json' }

    expect(response).to have_http_status(:success)
    json = JSON.parse(response.body)
    expect(json.size).to eq 1
  end
end


describe 'GET api/event_type/1.json', type: :request do
  it 'no event one event_type' do
    event = FactoryBot.create(:event)
    get "/api/event_types/#{event.event_type.id}.json", params: { format: 'json' }

    expect(response).to have_http_status(:success)
  
    json = JSON.parse(response.body)
    expect(json.size).to be > 1 
  end
end
# frozen_string_literal: true

require 'rails_helper'

describe 'GET catalog', type: :request do
  before(:all) do
    Event.all.each(&:destroy)
  end

  it 'no event one event_type' do
    FactoryBot.create(:event_type, include_in_catalog: true)
    get '/api/catalog', params: { format: 'json' }

    expect(response).to have_http_status(:success)

    json = JSON.parse(response.body)
    expect(json.size).to eq 1
  end
  it 'one event one event_type in catalog' do
    FactoryBot.create(:event)

    get '/api/catalog', params: { format: 'json' }

    expect(response).to have_http_status(:success)
    json = JSON.parse(response.body)
    expect(json.size).to eq 1
  end
  it 'one event + other event_type in catalog' do
    FactoryBot.create(:event)
    FactoryBot.create(:event_type, include_in_catalog: true)

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
  it 'event_type w/ codeless coupon   ' do
    FactoryBot.create(:event_type, include_in_catalog: true, deleted: false)
              .coupons << FactoryBot.create(:coupon, :codeless, percent_off: 20.0)

    get '/api/catalog', params: { format: 'json' }

    expect(response).to have_http_status(:success)
    json = JSON.parse(response.body)
    expect(json[0]['percent_off']).to eq '20.0'
  end

  it 'returns courses sorted by ordering field' do
    et_last = FactoryBot.create(:event_type, include_in_catalog: true, ordering: 100, name: 'Last Course')
    et_first = FactoryBot.create(:event_type, include_in_catalog: true, ordering: 10, name: 'First Course')
    et_middle = FactoryBot.create(:event_type, include_in_catalog: true, ordering: 50, name: 'Middle Course')

    get '/api/catalog', params: { format: 'json' }

    expect(response).to have_http_status(:success)
    json = JSON.parse(response.body)
    expect(json.size).to eq 3
    expect(json[0]['event_type_id']).to eq et_first.id
    expect(json[1]['event_type_id']).to eq et_middle.id
    expect(json[2]['event_type_id']).to eq et_last.id
  end

  it 'includes ordering field in response' do
    FactoryBot.create(:event_type, include_in_catalog: true, ordering: 25)

    get '/api/catalog', params: { format: 'json' }

    expect(response).to have_http_status(:success)
    json = JSON.parse(response.body)
    expect(json[0]['ordering']).to eq 25
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
describe 'GET api/event_type/1/testimonies', type: :request do
  it 'one testimony' do
    ev = FactoryBot.create(:event)
    FactoryBot.create(:participant, event: ev, testimony: 'Hi!')
    get "/api/event_types/#{ev.event_type.id}/testimonies", params: { format: 'json' }

    expect(response).to have_http_status(:success)

    json = JSON.parse(response.body)
    expect(json.size).to eq 1
  end
  it 'one empty testimony' do
    ev = FactoryBot.create(:event)
    FactoryBot.create(:participant, event: ev, testimony: '')
    get "/api/event_types/#{ev.event_type.id}/testimonies", params: { format: 'json' }

    expect(response).to have_http_status(:success)

    json = JSON.parse(response.body)
    expect(json.size).to eq 0
  end
end

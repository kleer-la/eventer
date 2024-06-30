# frozen_string_literal: true

require 'rails_helper'

describe 'API Events GET /event_types' do
  context 'one event w/JSON' do
    before(:example) do
      event_type = FactoryBot.create(:event_type)
      url = "/api/event_types/#{event_type.id}.json"
      get url
      @json = JSON.parse(response.body)
    end
    it 'JSON?' do
      expect(@json.count).to be > 0
    end
  end
  context 'testimonies' do
    it 'JSON?' do
      event_type = FactoryBot.create(:event_type)
      url = "/api/event_types/#{event_type.id}/testimonies.json"
      get url
      @json = JSON.parse(response.body)
      expect(@json.count).to eq 0
    end
    it 'One testimony' do
      participant = FactoryBot.create(:participant, testimony: 'Abradadabra')
      url = "/api/event_types/#{participant.event.event_type.id}/testimonies.json"
      get url
      @json = JSON.parse(response.body)
      expect(@json.count).to eq 1
      expect(@json[0]['testimony']).to eq 'Abradadabra'
    end
  end
end

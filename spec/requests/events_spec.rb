# frozen_string_literal: true

require 'rails_helper'

describe 'API Events GET /events' do
  #TODO duplicated with test on home
  context 'event list in JSON' do
    before(:example) do
      FactoryBot.create(:event)
      event_url = '/api/events.json'
      get event_url
      @json = JSON.parse(response.body)
    end
    it 'JSON?' do
      expect(@json.count).to be > 0
    end
  end
end

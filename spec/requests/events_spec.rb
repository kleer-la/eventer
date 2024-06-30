# frozen_string_literal: true

require 'rails_helper'

describe 'API Events GET /events' do
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
    it 'one public and visible course' # do
    #   expect(@parsed.xpath('//event').count).to be >= 1
    # end

    it 'course has a trainer' #do
    #   expect(@parsed.xpath('//event/trainers/trainer').count).to be >= 1
    # end
    it 'course has extra script' #do
    #   expect(@parsed.xpath('//event/extra-script').count).to be >= 1
    # end
    it 'course event-type has subtitle' #do
    #   expect(@parsed.xpath('//event/event-type/subtitle').count).to be >= 1
    # end
  end
end

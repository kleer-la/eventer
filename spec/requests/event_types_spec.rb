# frozen_string_literal: true

require 'rails_helper'

describe 'API Events GET /event_types' do
  include Rack::Test::Methods
  def app
    Rack::Builder.parse_file('config.ru').first
  end
  context 'one event_type XML' do
    before(:example) do
      @event_type = FactoryBot.create(:event_type)
      @url = "/api/event_types/#{@event_type.id}.xml"
      get @url
      @parsed = Nokogiri::XML(last_response.body)
    end
    it 'XML?' do
      expect(last_response.status).to eq 200
      expect(last_response.body).to start_with('<?xml')
    end

    it 'have event type' do
      expect(@parsed.xpath('//event-type').count).to eq 1
    end

    it 'course has no category' do
      expect(@parsed.xpath('//categories').count).to eq 1
    end
    it 'course has one category' do
      @event_type.categories << FactoryBot.create(:category)
      @event_type.save!

      get @url
      parsed = Nokogiri::XML(last_response.body)

      expect(parsed.xpath('//categories/category').count).to eq 1
    end
    it 'has canonical_slug' do
      get @url
      parsed = Nokogiri::XML(last_response.body)
      expect(parsed.xpath('//canonical-slug').count).to eq 1
    end
    it 'has deleted & noindex' do
      get @url
      parsed = Nokogiri::XML(last_response.body)
      expect(parsed.xpath('//deleted').count).to eq 1
      expect(parsed.xpath('//noindex').count).to eq 1
    end
    it 'has cover' do
      get @url
      parsed = Nokogiri::XML(last_response.body)
      expect(parsed.xpath('//cover').count).to eq 1
    end
  end

  context 'one event w/JSON' do
    before(:example) do
      event_type = FactoryBot.create(:event_type)
      url = "/api/event_types/#{event_type.id}.json"
      get url
      @json = JSON.parse(last_response.body)
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
      @json = JSON.parse(last_response.body)
      expect(@json.count).to eq 0
    end
    it 'One testimony' do
      participant = FactoryBot.create(:participant, testimony: 'Abradadabra')
      url = "/api/event_types/#{participant.event.event_type.id}/testimonies.json"
      get url
      @json = JSON.parse(last_response.body)
      expect(@json.count).to eq 1
      expect(@json[0]['testimony']).to eq 'Abradadabra'
    end
  end
end

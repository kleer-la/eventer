# frozen_string_literal: true

require 'rails_helper'

describe 'API Trainers GET /trainers' do
  include Rack::Test::Methods
  def app
    Rack::Builder.parse_file('config.ru').first
  end
  context 'trainer list in XML' do
    before(:example) do
      FactoryBot.create(:trainer, is_kleerer: true)
      event_url = '/api/kleerers.xml'
      get event_url
      @parsed = Nokogiri::XML(last_response.body)
    end
    it 'XML?' do
      expect(last_response.status).to eq 200
      expect(last_response.body).to start_with('<?xml')
    end

    it 'one trainer' do
      expect(@parsed.xpath('//trainers/trainer').count).to eq 1
    end
  end
end

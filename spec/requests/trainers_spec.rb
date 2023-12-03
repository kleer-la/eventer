# frozen_string_literal: true

require 'rails_helper'

describe 'API Trainers GET /trainers' do
  context 'trainer list in XML' do
    before(:example) do
      FactoryBot.create(:trainer, is_kleerer: true)
      event_url = '/api/kleerers.xml'
      get event_url
      @parsed = Nokogiri::XML(response.body)
    end
    it 'XML?' do
      expect(response.status).to eq 200
      expect(response.body).to start_with('<?xml')
    end

    it 'one trainer' do
      expect(@parsed.xpath('//trainers/trainer').count).to eq 1
    end
  end
end

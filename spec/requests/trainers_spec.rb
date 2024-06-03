# frozen_string_literal: true

require 'rails_helper'

describe 'API Trainers GET /kleerers' do
  context 'trainer list in JSON' do
    before(:example) do
      FactoryBot.create(:trainer, is_kleerer: true)
      event_url = '/api/kleerers.json'
      get event_url
    end

    it 'JSON?' do
      expect(response.status).to eq 200
      expect(response.content_type).to eq 'application/json; charset=utf-8'
    end

    it 'one trainer' do
      expect(JSON.parse(response.body).count).to eq 1
    end
  end
end

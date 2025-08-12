# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::NewsController, type: :controller do
  describe 'GET #index' do
    before do
      @visible_news = create(:news, title: 'Visible News', visible: true)
      @hidden_news = create(:news, title: 'Hidden News', visible: false)
    end

    it 'returns only visible news in JSON format' do
      get :index, format: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      news_titles = json_response.map { |item| item['title'] }
      expect(news_titles).to include('Visible News')
      expect(news_titles).not_to include('Hidden News')
    end

    it 'orders news by event_date descending' do
      create(:news,
             title: 'Old Visible News',
             event_date: 1.month.ago,
             visible: true)
      create(:news,
             title: 'New Visible News',
             event_date: 1.month.from_now,
             visible: true)

      get :index, format: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      # First item should be the most recent (new_visible)
      expect(json_response.first['title']).to eq('New Visible News')
    end

    it 'includes trainer information in the response' do
      trainer = create(:trainer, name: 'Test Trainer')
      news_with_trainer = create(:news, visible: true)
      news_with_trainer.trainers << trainer

      get :index, format: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      news_item = json_response.find { |item| item['id'] == news_with_trainer.id }
      expect(news_item['trainers']).to be_present
      expect(news_item['trainers'].first['name']).to eq('Test Trainer')
    end
  end

  describe 'GET #preview' do
    before do
      @visible_news = create(:news, title: 'Visible News', visible: true)
      @hidden_news = create(:news, title: 'Hidden News', visible: false)
    end

    it 'returns all news including hidden ones in JSON format' do
      get :preview, format: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      news_titles = json_response.map { |item| item['title'] }
      expect(news_titles).to include('Visible News')
      expect(news_titles).to include('Hidden News')
    end

    it 'orders news by event_date descending' do
      create(:news,
             title: 'Old Hidden News',
             event_date: 1.month.ago,
             visible: false)
      create(:news,
             title: 'New Visible News',
             event_date: 1.month.from_now,
             visible: true)

      get :preview, format: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      # First item should be the most recent regardless of visibility
      expect(json_response.first['title']).to eq('New Visible News')
    end

    it 'includes trainer information in the response' do
      trainer = create(:trainer, name: 'Test Trainer')
      hidden_news_with_trainer = create(:news, visible: false)
      hidden_news_with_trainer.trainers << trainer

      get :preview, format: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      news_item = json_response.find { |item| item['id'] == hidden_news_with_trainer.id }
      expect(news_item['trainers']).to be_present
      expect(news_item['trainers'].first['name']).to eq('Test Trainer')
    end

    it 'includes visible flag in the response' do
      get :preview, format: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      visible_item = json_response.find { |item| item['title'] == 'Visible News' }
      hidden_item = json_response.find { |item| item['title'] == 'Hidden News' }

      expect(visible_item['visible']).to be true
      expect(hidden_item['visible']).to be false
    end
  end
end

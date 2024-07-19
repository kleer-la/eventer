# frozen_string_literal: true

require 'rails_helper'

describe Api::EventTypesController do
  describe "GET 'event_types' (/api/event_types/#.<format>)" do
    it 'fetch a event_type' do
      et = FactoryBot.create(:event_type)
      get :show, params: { id: et.to_param, format: 'json' }
      expect(assigns(:event_type)).to eq et
    end
    it 'fetch a event_type' do
      et = FactoryBot.create(:event_type)
      ev = FactoryBot.create(:event, event_type: et)
      FactoryBot.create(:participant, event: ev, testimony: 'Hello, Joe', selected: true)

      get :show, params: { id: et.to_param, format: 'json' }
      expect(assigns(:event_type)).to eq et
    end
    it 'event_type w/external URL' do
      et = FactoryBot.create(:event_type, external_site_url: 'https://academia.kleer.la')
      ev = FactoryBot.create(:event, event_type: et)
      FactoryBot.create(:participant, event: ev, testimony: 'Hello, Joe', selected: true)

      get :show, params: { id: et.to_param, format: 'json' }
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response).to include('external_site_url')
    end
    it 'fetches an event_type with recommended content' do
      event_type = create(:event_type)
      recommended_event_type = create(:event_type)

      # Create a related content
      RecommendedContent.create(source: event_type, target: recommended_event_type, relevance_order: 50)

      get :show, params: { id: event_type.id, format: 'json' }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)

      expect(json_response['id']).to eq(event_type.id)
      expect(json_response['name']).to eq(event_type.name)

      expect(json_response['recommended']).to be_an(Array)
      expect(json_response['recommended'].length).to eq(1)

      recommended_item = json_response['recommended'].first
      expect(recommended_item['id']).to eq(recommended_event_type.id)
      expect(recommended_item['title']).to eq(recommended_event_type.name)
      # expect(recommended_item['subtitle']).to eq(recommended_article.description)
      expect(recommended_item['cover']).to eq(recommended_event_type.cover)
      expect(recommended_item['type']).to eq('event_type')
    end
    it 'fetches an event_type with recommended resource' do
      event_type = create(:event_type)
      recommended = create(:resource)

      # Create a related content
      RecommendedContent.create(source: event_type, target: recommended, relevance_order: 50)

      get :show, params: { id: event_type.id, format: 'json' }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)

      expect(json_response['id']).to eq(event_type.id)
      expect(json_response['name']).to eq(event_type.name)

      expect(json_response['recommended']).to be_an(Array)
      expect(json_response['recommended'].length).to eq(1)

      recommended_item = json_response['recommended'].first
      expect(recommended_item['id']).to eq(recommended.id)
      expect(recommended_item['type']).to eq('resource')
    end
  end
end

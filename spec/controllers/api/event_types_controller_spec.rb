# frozen_string_literal: true

require 'rails_helper'

describe Api::EventTypesController do
  describe "'event_types' (/api/event_types/#.<format>)" do
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

    it 'handles nil recommended content gracefully' do
      event_type = create(:event_type)
      # Create a recommended content with nil target
      RecommendedContent.create(source: event_type, target: nil, relevance_order: 50)

      get :show, params: { id: event_type.id, format: 'json' }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['recommended']).to be_an(Array)
      expect(json_response['recommended']).to be_empty
    end

    it 'handles non-existent event type' do
      # Try to get a non-existent event type ID
      get :show, params: { id: 999_999, format: 'json' }

      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)
      expect(json_response).to include('error')
    end

    it 'handles empty recommended contents' do
      event_type = create(:event_type)
      # Don't create any recommended content

      get :show, params: { id: event_type.id, format: 'json' }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['recommended']).to be_an(Array)
      expect(json_response['recommended']).to be_empty
    end

    context 'seo_title' do
      it 'returns seo_title when set' do
        event_type = create(:event_type, seo_title: 'Custom SEO Title')

        get :show, params: { id: event_type.id, format: 'json' }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['seo_title']).to eq('Custom SEO Title')
      end

      it 'returns name as seo_title when seo_title is blank' do
        event_type = create(:event_type, name: 'My Event Name', seo_title: nil)

        get :show, params: { id: event_type.id, format: 'json' }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['seo_title']).to eq('My Event Name')
      end

      it 'returns name as seo_title when seo_title is empty string' do
        event_type = create(:event_type, name: 'My Event Name', seo_title: '')

        get :show, params: { id: event_type.id, format: 'json' }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['seo_title']).to eq('My Event Name')
      end
    end
  end
end

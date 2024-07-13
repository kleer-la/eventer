# frozen_string_literal: true

require 'rails_helper'

describe Api::ServiceAreasController do
  describe "GET 'ServiceAreas/#' (/api/services/#.<format>)" do
    it 'fetch a ServiceArea' do
      sa = FactoryBot.create(:service_area)
      get :show, params: { id: sa.slug, format: 'json' }
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['slug']).to eq(sa.slug)
    end
    it 'responds with error for unknown ServiceArea' do
      get :show, params: { id: 'unknown-slug', format: 'json' }
      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('ServiceArea not found')
    end
    it 'fetches a ServiceArea by included Service slug' do
      service_area = FactoryBot.create(:service_area)
      service = FactoryBot.create(:service, service_area:)

      get :show, params: { id: service.slug, format: 'json' }
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['slug']).to eq(service_area.slug)
    end
    describe 'Redirect' do
      before do
        @service_area = FactoryBot.create(:service_area)
        @service = FactoryBot.create(:service, service_area: @service_area)
      end

      it 'No slug changed (by ServiceArea)' do
        get :show, params: { id: @service_area.slug, format: 'json' }
        json_response = JSON.parse(response.body)
        expect(json_response['slug_old']).to be nil
        expect(json_response['services'][0]['slug_old']).to be nil
      end
      it 'No slug changed (by Service)' do
        get :show, params: { id: @service.slug, format: 'json' }
        json_response = JSON.parse(response.body)
        expect(json_response['slug_old']).to be nil
        expect(json_response['services'][0]['slug_old']).to be nil
      end
      it 'ServiceArea slug changed (by ServiceArea)' do
        old_slug = @service_area.slug
        @service_area.slug = 'new-slug'
        @service_area.save

        get :show, params: { id: old_slug, format: 'json' }
        json_response = JSON.parse(response.body)
        expect(json_response['slug_old']).to eq old_slug
        expect(json_response['services'][0]['slug_old']).to be nil
      end
      it 'ServiceArea slug changed (by Service)' do
        @service_area.slug = 'new-slug'
        @service_area.save

        get :show, params: { id: @service.slug, format: 'json' }
        json_response = JSON.parse(response.body)
        expect(json_response['slug_old']).to eq nil
        expect(json_response['services'][0]['slug_old']).to be nil
      end
      it 'Service slug changed (by ServiceArea)' do
        @service.slug = 'new-slug'
        @service.save

        get :show, params: { id: @service_area.slug, format: 'json' }
        json_response = JSON.parse(response.body)
        expect(json_response['slug_old']).to eq nil
        expect(json_response['services'][0]['slug_old']).to be nil
      end
      it 'Service slug changed (by Service)' do
        old_slug = @service.slug
        @service.slug = 'new-slug'
        @service.save

        get :show, params: { id: old_slug, format: 'json' }
        json_response = JSON.parse(response.body)
        expect(json_response['slug_old']).to eq nil
        expect(json_response['services'][0]['slug_old']).to eq old_slug
      end
    end
  end
end

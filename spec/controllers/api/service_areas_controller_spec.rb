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
      service = FactoryBot.create(:service, service_area: service_area)

      get :show, params: { id: service.slug, format: 'json' }
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['slug']).to eq(service_area.slug)
    end
  end
  # describe "GET 'Articles' (/api/articles.<format>)" do
  #   it 'Articles list w/o body' do
  #     ar = FactoryBot.create(:article)

  #     get :index, params: {  format: 'json' }
  #     expect(response).to have_http_status(:ok)
  #     json_response = JSON.parse(response.body)
  #     expect(json_response).not_to include('body')
  #   end
  # end
end

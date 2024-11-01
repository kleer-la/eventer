# frozen_string_literal: true

require 'rails_helper'

describe Api::ServiceAreasController do
  describe "GET 'index'" do
    before do
      @regular_service = FactoryBot.create(:service_area, visible: true, is_training_program: false)
      @training_program = FactoryBot.create(:service_area, visible: true, is_training_program: true)
    end

    it 'shows only regular services in /services.json' do
      get :index, params: { format: 'json' }
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      service_slugs = json_response.map { |sa| sa['slug'] }
      expect(service_slugs).to include(@regular_service.slug)
      expect(service_slugs).not_to include(@training_program.slug)
    end

    it 'shows only training programs in /programs.json' do
      get :programs, params: { format: 'json' }
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      program_slugs = json_response.map { |sa| sa['slug'] }
      expect(program_slugs).to include(@training_program.slug)
      expect(program_slugs).not_to include(@regular_service.slug)
    end
  end

  describe "GET 'ServiceAreas/#' (/api/services/#.<format>)" do
    let(:service_area) { FactoryBot.create(:service_area) }
    let!(:visible_service) { FactoryBot.create(:service, service_area:, visible: true) }
    let!(:invisible_service) { FactoryBot.create(:service, service_area:, visible: false) }

    context 'fetch visible' do
      it 'fetch a ServiceArea' do
        get :show, params: { id: service_area.slug, format: 'json' }
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['slug']).to eq(service_area.slug)
      end
      it 'responds with error for unknown ServiceArea' do
        get :show, params: { id: 'unknown-slug', format: 'json' }
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('ServiceArea not found')
      end
      it 'fetches a ServiceArea by included Service slug' do
        get :show, params: { id: visible_service.slug, format: 'json' }
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['slug']).to eq(service_area.slug)
      end
      it 'shows only visible services' do
        get :show, params: { id: service_area.slug, format: 'json' }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        service_ids = json_response['services'].map { |s| s['id'] }

        expect(service_ids).to include(visible_service.id)
        expect(service_ids).not_to include(invisible_service.id)
      end
    end
    context 'preview endpoint' do
      it 'shows all services regardless of visibility' do
        get :preview, params: { id: service_area.slug, format: 'json' }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        service_ids = json_response['services'].map { |s| s['id'] }

        expect(service_ids).to include(visible_service.id)
        expect(service_ids).to include(invisible_service.id)
      end
    end
    describe 'Redirect' do
      before do
        @service_area = FactoryBot.create(:service_area)
        @service = FactoryBot.create(:service, service_area: @service_area, visible: true)
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

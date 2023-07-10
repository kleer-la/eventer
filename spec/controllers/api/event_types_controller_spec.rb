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
  end

end

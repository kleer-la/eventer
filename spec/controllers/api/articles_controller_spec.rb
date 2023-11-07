# frozen_string_literal: true

require 'rails_helper'

describe Api::ArticlesController do
  describe "GET 'Articles/#' (/api/articles/#.<format>)" do
    it 'fetch a article' do
      ar = FactoryBot.create(:article)
      get :show, params: { id: ar.id, format: 'json' }
      expect(assigns(:article)).to eq ar
    end
  end
  describe "GET 'Articles' (/api/articles.<format>)" do
    it 'Articles list w/o body' do
      ar = FactoryBot.create(:article)

      get :index, params: {  format: 'json' }
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response).not_to include('body')
    end
  end
end

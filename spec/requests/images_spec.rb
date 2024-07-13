# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Images', type: :request do
  before(:all) do
    FileStoreService.create_null
  end
  describe 'GET /index' do
    it 'returns http success' do
      get '/images'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /new' do
    it 'returns http success' do
      get '/images/new'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /create' do
    it 'returns http success' do
      post '/images/create'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /show' do
    it 'returns http success' do
      get '/images/show'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /edit' do
    it 'returns http success' do
      get '/images/edit'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'UTT /update' do
    it 'returns http success' do
      put '/images/update'
      expect(response).to have_http_status(:success)
    end
  end
end

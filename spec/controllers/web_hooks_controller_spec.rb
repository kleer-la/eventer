# frozen_string_literal: true

require 'rails_helper'

describe WebHooksController do # slow: true
  describe "GET 'index' (/api/events.<format>)" do
    it 'returns http success' do
      get :index
      expect(response).to be_successful
    end
  end
  describe 'POST ' do
    it 'assigns a newly created trainer as @trainer' do
      post :post
      expect(response).not_to be_successful
    end
  end
end
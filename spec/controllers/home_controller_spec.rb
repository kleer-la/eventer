# frozen_string_literal: true

require 'rails_helper'

describe HomeController do
  describe "GET 'index' (/api/events.<format>)" do
    it 'returns http success' do
      get :index, params: { format: 'xml' }
      expect(response).to be_successful
    end
    it 'returns events' do
      event = FactoryBot.create(:event)
      get :index, params: { format: 'xml' }
      expect(assigns(:events)).to eq [event]
    end
    it 'returns non draft events' do
      FactoryBot.create(:event, place: 'here')
      FactoryBot.create(:event, place: 'there', draft: true)
      get :index, params: { format: 'xml' }
      expect(assigns(:events).map(&:place)).to eq ['here']
    end
  end

  describe "GET 'show' (/api/events.<format>)" do
    it 'fetch a course' do
      event = FactoryBot.create(:event)
      get :show, params: { id: event.to_param, format: 'xml' }
      expect(assigns(:event)).to eq event
    end
    it 'illegal course not found' do
      expect do
        get :show, params: { id: 1 }
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
    it 'draft course found' do
      event = FactoryBot.create(:event, draft: false)
      get :show, params: { id: event.to_param, format: 'xml' }
      expect(assigns(:event)).to eq event
    end
  end
end

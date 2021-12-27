# frozen_string_literal: true

require 'rails_helper'

describe ParticipantsController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/events/1/participants')).to route_to('participants#index', event_id: '1')
    end

    it 'routes to #new' do
      expect(get('/events/1/participants/new')).to route_to('participants#new', event_id: '1')
    end

    it 'routes to #show' do
      expect(get('/events/1/participants/1')).to route_to('participants#show', id: '1', event_id: '1')
    end

    it 'routes to #edit' do
      expect(get('/events/1/participants/1/edit')).to route_to('participants#edit', id: '1', event_id: '1')
    end

    it 'routes to #create' do
      expect(post('/events/1/participants')).to route_to('participants#create', event_id: '1')
    end

    it 'routes to #update' do
      expect(put('/events/1/participants/1')).to route_to('participants#update', id: '1', event_id: '1')
    end

    it 'routes to #destroy' do
      expect(delete('/events/1/participants/1')).to route_to('participants#destroy', id: '1', event_id: '1')
    end
    it 'routes to #batch_load' do
      expect(post('events/1/participants_batch_load')).to route_to('participants#batch_load', event_id: '1')
    end
  end
end

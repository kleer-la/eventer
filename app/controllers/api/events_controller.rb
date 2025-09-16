# frozen_string_literal: true

module Api
  class EventsController < ApplicationController
    skip_before_action :verify_authenticity_token

    # GET /api/events/:id.json
    def show
      @event = Event.find(params[:id])
      render json: { id: @event.id, event_type_id: @event.event_type_id }
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Event not found' }, status: :not_found
    end
  end
end
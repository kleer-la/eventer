# frozen_string_literal: true

module Api
  class EventsController < ApplicationController
    skip_before_action :verify_authenticity_token

    # GET /api/events/:id.json
    def show
      @event = Event.find(params[:id])
      render json: @event.as_json(include: :event_type)
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Event not found' }, status: :not_found
    end
  end
end
# frozen_string_literal: true

module Api
  class ServiceAreasController < ApplicationController
    # GET /api/service_areas
    def index
      @service_areas = ServiceArea.where(visible: true).includes(:services)

      render json: @service_areas.as_json(include: {
        services: {
          only: [:name, :card_description]
        }
      }, only: %i[id name abstract])
    end

    # GET /api/service_areas/:id
    def show
      @service_area = ServiceArea.find(params[:id])
      render json: @service_area.as_json(include: {
        services: {
          only: [:name, :subtitle]
        }
      }, only: [:id, :name])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'ServiceArea not found' }, status: :not_found
    end
  end
end

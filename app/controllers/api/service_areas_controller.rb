# frozen_string_literal: true

module Api
  class ServiceAreasController < ApplicationController
    # GET /api/service_areas
    def index
      @service_areas = ServiceArea.where(visible: true).includes(:services)

      # needs the map bc the abstract.body.to_s
      render json: @service_areas.map { |service_area|
        {
          id: service_area.id,
          slug: service_area.slug,
          name: service_area.name,
          abstract: service_area.abstract.body.to_s, # Get just the content of the abstract
          primary_color: service_area.primary_color,
          secondary_color: service_area.secondary_color,
          services: service_area.services.map { |service|
            {
              name: service.name,
              card_description: service.card_description
            }
          }
        }
      }
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

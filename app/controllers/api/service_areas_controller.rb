# frozen_string_literal: true

module Api
  class ServiceAreasController < ApplicationController
    # GET /api/service_areas
    def index
      @service_areas = ServiceArea.where(visible: true).includes(:services)

      # needs the map bc the rich text.body.to_s
      render json: @service_areas.map { |service_area|
        {
          id: service_area.id,
          slug: service_area.slug,
          name: service_area.name,
          icon: service_area.icon,
          summary: service_area.summary.body.to_s, # Get just the content of the rich text
          primary_color: service_area.primary_color,
          secondary_color: service_area.secondary_color,
          services: service_area.services.map { |service|
            {
              name: service.name,
              subtitle: service.subtitle
            }
          }
        }
      }
    end

    # GET /api/service_areas/:id
    def show
      service_area = ServiceArea.friendly.find(params[:id])
      render json: {
        id: service_area.id,
        slug: service_area.slug,
        name: service_area.name,
        icon: service_area.icon,
        summary: service_area.summary.body.to_s,
        primary_color: service_area.primary_color,
        secondary_color: service_area.secondary_color,
        slogan: service_area.slogan.body.to_s,
        subtitle: service_area.subtitle.body.to_s,
        description: service_area.description.body.to_s,
        side_image: service_area.side_image,
        target: service_area.target.body.to_s,
        value_proposition: service_area.value_proposition.body.to_s,
        services: service_area.services.map { |service|
          {
            name: service.name,
            subtitle: service.subtitle,
            value_proposition: service.value_proposition.body.to_s,
            outcomes: service.outcomes_list,
            target: service.target.body.to_s,
          }
        }
      }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'ServiceArea not found' }, status: :not_found
    end
  end
end

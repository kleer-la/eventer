# frozen_string_literal: true

module Api
  class ServiceAreasController < ApplicationController
    # GET /api/service_areas
    def index
      @service_areas = ServiceArea.where(visible: true).order(:ordering).includes(:services)

      # needs the map bc the rich text.body.to_s
      render json: @service_areas.map { |service_area|
        {
          id: service_area.id,
          slug: service_area.slug,
          name: service_area.name,
          icon: service_area.icon,
          summary: service_area.summary.body.to_s, # Get just the content of the rich text
          cta_message: service_area.cta_message.body.to_s,
          primary_color: service_area.primary_color,
          secondary_color: service_area.secondary_color,
          services: service_area.services.map { |service|
            {
              id: service.id,
              slug: service.slug,
              name: service.name,
              subtitle: service.subtitle
            }
          },
          testimonies: service_area.testimonies.where(stared: true).map { |testimony|
            {
              first_name: testimony.first_name,
              last_name: testimony.last_name,
              profile_url: testimony.profile_url,
              photo_url: testimony.photo_url,
              service: testimony.service.name,
              testimony: testimony.testimony.body.to_s
            }
          }
        }
      }
    end

    # GET /api/service_areas/:id
    def show
      service_area = find_area_or_service(params[:id])
      unless service_area.present?
        return render json: { error: 'ServiceArea not found' }, status: :not_found
      end

      render json: {
        id: service_area.id,
        slug: service_area.slug,
        name: service_area.name,
        icon: service_area.icon,
        summary: service_area.summary.body.to_s,
        cta_message: service_area.cta_message.body.to_s,
        primary_color: service_area.primary_color,
        secondary_color: service_area.secondary_color,
        slogan: service_area.slogan.body.to_s,
        subtitle: service_area.subtitle.body.to_s.gsub('<h1>', '<h2>').gsub('</h1>', '</h2>'),
        description: service_area.description.body.to_s,
        side_image: service_area.side_image,
        target_title: service_area.target_title,
        target: service_area.target&.body.to_s,
        value_proposition: service_area.value_proposition.body.to_s,
        seo_title: service_area.seo_title,
        seo_description: service_area.seo_description,
        services: service_area.services.map { |service|
          {
            id: service.id,
            slug: service.slug,
            name: service.name,
            subtitle: service.subtitle.gsub('<h1>', '<h2>').gsub('</h1>', '</h2>'),
            value_proposition: service.value_proposition.body.to_s,
            outcomes: service.outcomes_list,
            definitions: service.definitions.body.to_s,
            program: service.program_list,
            target: service.target.body.to_s,
            pricing: service.pricing,
            faq: service.faq_list,
            brochure: service.brochure,
            side_image: service.side_image,
          }
        },
      }
    end

    private

    def find_area_or_service(slug)
      ServiceArea.friendly.find(slug)
    rescue ActiveRecord::RecordNotFound
      begin
        service = Service.friendly.find(slug)
        service.service_area if service.present?
      rescue ActiveRecord::RecordNotFound
        nil # If neither ServiceArea nor Service is found, return nil
      end
    end
  end
end

# frozen_string_literal: true

module Api
  class ServiceAreasController < ApplicationController
    # GET /api/service_areas
    def index
      list ServiceArea.where(visible: true, is_training_program: false).order(:ordering).includes(:services)
    end

    def programs
      list ServiceArea.where(visible: true, is_training_program: true).order(:ordering).includes(:services)
    end

    def list(service_areas)
      # needs the map bc the rich text.body.to_s
      render json: service_areas.map { |service_area|
        {
          id: service_area.id,
          slug: service_area.slug,
          name: service_area.name,
          icon: service_area.icon,
          summary: service_area.summary.body.to_s, # Get just the content of the rich text
          cta_message: service_area.cta_message.body.to_s,
          primary_color: service_area.primary_color,
          secondary_color: service_area.secondary_color,
          services: service_area.services.order(:ordering).map do |service|
            {
              id: service.id,
              slug: service.slug,
              name: service.name,
              subtitle: service.subtitle
            }
          end,
          testimonies: service_area.testimonies.where(stared: true).map do |testimony|
            {
              first_name: testimony.first_name,
              last_name: testimony.last_name,
              profile_url: testimony.profile_url,
              photo_url: testimony.photo_url,
              service: testimony.service.name,
              testimony: testimony.testimony.body.to_s
            }
          end
        }
      }
    end

    # GET /api/service_areas/:id
    def show
      services_area_json(visible: true)
    end

    def preview
      services_area_json(visible: false)
    end

    def services_area_json(visible: false)
      req_slug = params[:id]
      service_area, service_area_chg, service_chg = find_area_or_service(req_slug)
      return render(json: { error: 'ServiceArea not found' }, status: :not_found) unless service_area.present?

      services = service_area.services
      services = services.where(visible: true) if visible

      render json: {
        id: service_area.id,
        slug: service_area.slug,
        slug_old: service_area_chg,
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
        services: services2json(services, service_chg, req_slug)
      }
    end

    private

    def services2json(services, service_chg, req_slug)
      services.order(:ordering).map do |service|
        {
          id: service.id,
          slug: service.slug,
          slug_old: service_chg.nil? || service.slug != service_chg ? nil : req_slug,
          name: service.name,
          subtitle: service.subtitle.gsub('<h1>', '<h2>').gsub('</h1>', '</h2>'),
          value_proposition: service.value_proposition.body.to_s,
          outcomes: service.outcomes_list,
          definitions: content_or_nil(service.definitions),
          program: service.program_list,
          target: service.target.body.to_s,
          pricing: service.pricing,
          faq: service.faq_list,
          brochure: service.brochure,
          side_image: service.side_image,
          recommended: service.recommended
        }
      end
    end

    def content_or_nil(active_text)
      active_text.blank? ? nil : active_text.body.to_s
    end

    def find_area_or_service(slug)
      service_area = ServiceArea.friendly.find(slug)
      [service_area, service_area.slug != slug ? slug : nil, nil]
    rescue ActiveRecord::RecordNotFound
      begin
        service = Service.friendly.find(slug)
        [service.service_area, nil, service.slug != slug ? service.slug : nil]
      rescue ActiveRecord::RecordNotFound
        [nil, nil, nil] # If neither ServiceArea nor Service is found
      end
    end
  end
end

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
          lang: service_area.lang,
          name: service_area.name,
          icon: service_area.icon,
          summary: service_area.summary.body.to_s, # Get just the content of the rich text
          cta_message: service_area.cta_message.body.to_s,
          primary_color: service_area.primary_color,
          primary_font_color: service_area.primary_font_color,
          secondary_color: service_area.secondary_color,
          secondary_font_color: service_area.secondary_font_color,
          is_training_program: service_area.is_training_program,
          ordering: service_area.ordering,
          # Only what is published: the show endpoint has always filtered these,
          # and the list not doing it put an unpublished service into the
          # sitemap, which then declared a URL answering 404.
          services: service_area.services.where(published: true).order(:ordering).map do |service|
            {
              id: service.id,
              slug: service.slug,
              name: service.name,
              subtitle: service.subtitle
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

      lang = service_area.lang

      services = service_area.services
      services = services.where(published: true) if visible

      render json: {
        id: service_area.id,
        slug: service_area.slug,
        slug_old: service_area_chg,
        lang: service_area.lang,
        name: service_area.name,
        icon: service_area.icon,
        summary: service_area.summary.body.to_s,
        cta_message: service_area.cta_message.body.to_s,
        primary_color: service_area.primary_color,
        primary_font_color: service_area.primary_font_color,
        secondary_color: service_area.secondary_color,
        secondary_font_color: service_area.secondary_font_color,
        slogan: service_area.slogan.body.to_s,
        subtitle: service_area.subtitle.body.to_s.gsub('<h1>', '<h2>').gsub('</h1>', '</h2>'),
        description: service_area.description.body.to_s,
        side_image: service_area.side_image,
        target_title: service_area.target_title,
        target: service_area.target&.body.to_s,
        value_proposition: service_area.value_proposition.body.to_s,
        value_proposition_title: service_area.value_proposition_title,
        seo_title: service_area.seo_title,
        seo_description: service_area.seo_description,
        is_training_program: service_area.is_training_program,
        recommended_way_title: service_area.recommended_way_title,
        recommended_way_note: service_area.recommended_way_note,
        recommended_way_summary: service_area.recommended_way_summary_html,
        recommended_way_details: service_area.recommended_way_details_html,
        # The area as an offering in itself: the same blocks a service has, so
        # the page can present and sell it without a service underneath.
        outcomes: service_area.outcomes_list,
        definitions: content_or_nil(service_area.definitions),
        program: service_area.program_list,
        pricing: service_area.pricing,
        faq: service_area.faq_list,
        brochure: service_area.brochure,
        # Texts of its own for the hero and contact blocks; nil = the site uses
        # the shared "service-area" Page.
        hero_cta_text: service_area.hero_cta_text.presence,
        hero_secondary_cta_text: service_area.hero_secondary_cta_text.presence,
        hero_secondary_cta_target: service_area.hero_secondary_cta_target.presence,
        hero_note: service_area.hero_note.presence,
        contact_title: service_area.contact_title.presence,
        contact_text: service_area.contact_text.presence,
        contact_cta_text: service_area.contact_cta_text.presence,
        recommended: service_area.recommended(lang:),
        testimonies: area_testimonies(service_area),
        services: services2json(services, service_chg, req_slug, lang)
      }
    end

    private

    # What clients said about the area's services, starred ones only, in the
    # shape the course pages read (fname/lname, plain text) — like them, ten at most.
    def area_testimonies(service_area)
      service_area.testimonies.starred.includes(:rich_text_testimony).first(10).map(&:api_json)
    end

    def services2json(services, service_chg, req_slug, lang)
      services.order(:ordering).map do |service|
        {
          id: service.id,
          slug: service.slug,
          slug_old: service_chg.nil? || service.slug != service_chg ? nil : req_slug,
          name: service.name,
          seo_title: service.seo_title,
          seo_description: service.seo_description,
          subtitle: service.subtitle.gsub('<h1>', '<h2>').gsub('</h1>', '</h2>'),
          card_description: service.card_description,
          value_proposition: service.value_proposition.body.to_s,
          outcomes: service.outcomes_list,
          definitions: content_or_nil(service.definitions),
          program: service.program_list,
          target: service.target.body.to_s,
          pricing: service.pricing,
          faq: service.faq_list,
          brochure: service.brochure,
          side_image: service.side_image,
          recommended: service.recommended(lang:),
          recommended_way_title: service.recommended_way_title,
          recommended_way_note: service.recommended_way_note,
          recommended_way_summary: service.recommended_way_summary_html,
          recommended_way_details: service.recommended_way_details_html
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

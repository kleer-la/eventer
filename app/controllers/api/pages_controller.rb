# frozen_string_literal: true

module Api
  class PagesController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

    def show
      page = Page.find_by_param!(params[:id])
      render json: page,
             methods: %i[recommended],
             only: %i[name seo_title seo_description lang canonical cover template show_in_footer],
             include: { sections: { only: %i[slug title content cta_text cta_url position] } }
    end

    # Lists pages flagged to appear in the global footer; consumed by
    # website17 to render the footer link list without hardcoded paths.
    def footer
      pages = Page.where(show_in_footer: true).order(:lang, :name)
      render json: pages, only: %i[name slug lang]
    end

    private

    def record_not_found
      render json: { error: 'Page not found' }, status: :not_found
    end
  end
end

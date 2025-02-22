# frozen_string_literal: true

module Api
  class PagesController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

    def show
      page = Page.find_by_param!(params[:id])
      render json: page,
             methods: %i[recommended],
             only: %i[seo_title seo_description lang canonical cover],
             include: { sections: { only: %i[slug title content position] } }
    end

    private

    def record_not_found
      render json: { error: 'Page not found' }, status: :not_found
    end
  end
end

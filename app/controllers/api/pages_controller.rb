# frozen_string_literal: true

module Api
  class PagesController < ApplicationController
    # GET /articles/1
    def show
      page = Page.find_by_param(params[:id])
      render json: page,
             methods: %i[recommended],
             only: %i[seo_title seo_description lang canonical]
    end
  end
end

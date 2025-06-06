module Api
  class ShortUrlsController < ApplicationController
    def show
      short_url = ShortUrl.find(params[:short_code])
      short_url.increment!(:click_count)
      render json: { original_url: short_url.original_url }
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Short URL not found' }, status: :not_found
    end
  end
end
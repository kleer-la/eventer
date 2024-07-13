# frozen_string_literal: true

module Api
  module V3
    class PodcastsController < ApplicationController
      def index
        @podcasts = Podcast.includes(:episodes).all
        render json: @podcasts.as_json(
          only: %i[title youtube_url spotify_url thumbnail_url],
          methods: [:description_body],
          include: {
            episodes: {
              only: %i[season episode title youtube_url spotify_url thumbnail_url published_at],
              methods: [:description_body]
            }
          }
        )
      end
    end
  end
end

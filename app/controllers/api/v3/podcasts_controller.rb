# frozen_string_literal: true

module Api
  module V3
    class PodcastsController < ApplicationController
      EPISODE_FIELDS = %i[season episode title youtube_url spotify_url thumbnail_url released_at].freeze

      # Only the episodes we publish on our own site. `released_at` is a
      # different thing: when the episode came out on Spotify or YouTube.
      def index
        podcasts = Podcast.includes(:episodes).all
        render json: podcasts.map { |podcast| podcast_json(podcast) }
      end

      private

      def podcast_json(podcast)
        podcast.as_json(only: %i[title youtube_url spotify_url thumbnail_url],
                        methods: [:description_body])
               .merge('episodes' => published_episodes(podcast))
      end

      # select, not a where: the episodes are already preloaded.
      def published_episodes(podcast)
        podcast.episodes.select(&:published)
               .map { |episode| episode.as_json(only: EPISODE_FIELDS, methods: [:description_body]) }
      end
    end
  end
end

# frozen_string_literal: true

class ListPodcastsTool < AuthenticatedTool
  tool_name 'list_podcasts'
  requires_permission :read, Podcast

  description 'Lists the podcasts with how many episodes each one has and where it is published.'

  arguments do
    optional(:query).filled(:string).description('Substring matched against the title')
    optional(:limit).filled(:integer).description("How many to return (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
  end

  def call(query: nil, limit: DEFAULT_LIMIT)
    scope = Podcast.includes(:episodes).order(:title)
    scope = scope.where('title LIKE ?', "%#{query}%") if query.present?

    podcasts = scope.limit(limit.clamp(1, MAX_LIMIT)).map { |podcast| summary(podcast) }
    listing(:podcasts, podcasts, total: scope.count, narrow: 'query')
  end

  private

  def summary(podcast)
    { id: podcast.id, title: podcast.title, episodes: podcast.episodes.size,
      spotify_url: podcast.spotify_url, youtube_url: podcast.youtube_url }
  end
end

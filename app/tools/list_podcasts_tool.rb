# frozen_string_literal: true

class ListPodcastsTool < AuthenticatedTool
  tool_name 'list_podcasts'
  requires_permission :read, Podcast

  description 'Lists the podcasts with how many episodes each one has and where it is published.'

  arguments do
    optional(:query).filled(:string).description('Substring matched against the title')
  end

  def call(query: nil)
    scope = Podcast.includes(:episodes).order(:title)
    scope = scope.where('title LIKE ?', "%#{query}%") if query.present?

    { count: scope.size,
      podcasts: scope.map do |podcast|
        { id: podcast.id, title: podcast.title, episodes: podcast.episodes.size,
          spotify_url: podcast.spotify_url, youtube_url: podcast.youtube_url }
      end }.to_json
  end
end

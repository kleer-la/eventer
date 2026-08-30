# frozen_string_literal: true

class GetPodcastTool < AuthenticatedTool
  tool_name 'get_podcast'
  requires_permission :read, Podcast

  description <<~MD
    Returns one podcast with its description and every episode, newest first.
    Descriptions are rich text, so they come back as HTML.
  MD

  arguments do
    required(:id).filled(:integer).description('Numeric id of the podcast')
  end

  def call(id:)
    podcast = Podcast.find(id)
    { id: podcast.id, title: podcast.title, description: podcast.description_body,
      spotify_url: podcast.spotify_url, youtube_url: podcast.youtube_url,
      thumbnail_url: podcast.thumbnail_url,
      episodes: podcast.episodes.order(season: :desc, episode: :desc).map { |e| episode(e) } }.to_json
  rescue ActiveRecord::RecordNotFound
    { status: 'error', errors: ["No podcast with id #{id}"] }.to_json
  end

  private

  def episode(episode)
    { id: episode.id, season: episode.season, episode: episode.episode, title: episode.title,
      published_at: episode.published_at, spotify_url: episode.spotify_url,
      youtube_url: episode.youtube_url }
  end
end

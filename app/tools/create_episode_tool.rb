# frozen_string_literal: true

class CreateEpisodeTool < AuthenticatedTool
  tool_name 'create_episode'
  requires_permission :create, Episode

  description <<~MD
    Adds an episode to a podcast. Season, number and publication date are all
    required, and the description is rich text.

    The preview warns if that season and number already exist in the podcast —
    nothing stops duplicates, so it is worth reading before confirming.
  MD

  arguments do
    required(:podcast_id).filled(:integer).description('Numeric id of the podcast it belongs to')
    required(:title).filled(:string).description('Episode title')
    required(:description).filled(:string).description('Description; HTML is accepted')
    required(:season).filled(:integer).description('Season number, 1 or more')
    required(:episode).filled(:integer).description('Episode number within the season, 1 or more')
    required(:published_at).filled(:string).description('Publication date, YYYY-MM-DD')
    optional(:spotify_url).filled(:string).description('Spotify link')
    optional(:youtube_url).filled(:string).description('YouTube link')
    optional(:thumbnail_url).filled(:string).description('Cover image URL')
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = save')
  end

  def call(podcast_id:, confirm: false, **fields)
    podcast = Podcast.find(podcast_id)
    EpisodeWriteService.new(ability: ability, record: podcast.episodes.build, **fields)
                       .call(confirm: confirm).to_json
  rescue ActiveRecord::RecordNotFound
    { status: 'error', errors: ["No podcast with id #{podcast_id}"] }.to_json
  end
end

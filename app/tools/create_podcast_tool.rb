# frozen_string_literal: true

class CreatePodcastTool < AuthenticatedTool
  tool_name 'create_podcast'
  requires_permission :create, Podcast

  description <<~MD
    Creates a podcast. Title and description are both required; the description
    is rich text, so HTML is accepted.

    Two steps: confirm=false (the default) previews without saving. Episodes are
    added afterwards with create_episode.
  MD

  arguments do
    required(:title).filled(:string).description('Podcast title')
    required(:description).filled(:string).description('Description; HTML is accepted')
    optional(:spotify_url).filled(:string).description('Spotify link')
    optional(:youtube_url).filled(:string).description('YouTube link')
    optional(:thumbnail_url).filled(:string).description('Cover image URL')
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = save')
  end

  def call(confirm: false, **fields)
    PodcastWriteService.new(ability: ability, **fields).call(confirm: confirm).to_json
  end
end

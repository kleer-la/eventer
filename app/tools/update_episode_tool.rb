# frozen_string_literal: true

class UpdateEpisodeTool < AuthenticatedTool
  tool_name 'update_episode'
  requires_permission :update, Episode

  description <<~MD
    Edits an episode by id. Only the fields you pass are touched. Previews unless
    confirm=true. To change part of the description, prefer `replacements`:
    `description` is the only field it patches, and it is matched as HTML.
  MD

  arguments do
    required(:id).filled(:integer).description('Numeric id of the episode')
    optional(:title).filled(:string).description('Episode title')
    optional(:description).filled(:string).description('Description; HTML is accepted')
    optional(:season).filled(:integer).description('Season number')
    optional(:episode).filled(:integer).description('Episode number within the season')
    optional(:released_at).filled(:string)
                          .description('When it came out on Spotify / YouTube, YYYY-MM-DD')
    optional(:published).filled(:bool).description('Show or hide it on the site')
    optional(:spotify_url).filled(:string).description('Spotify link')
    optional(:youtube_url).filled(:string).description('YouTube link')
    optional(:thumbnail_url).filled(:string).description('Cover image URL')
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = save')
    instance_exec(&ApplicationTool::REPLACEMENTS)
  end

  def call(id:, confirm: false, **fields)
    episode = Episode.find(id)
    EpisodeWriteService.new(ability: ability, record: episode, **fields).call(confirm: confirm).to_json
  rescue ActiveRecord::RecordNotFound
    { status: 'error', errors: ["No episode with id #{id}"] }.to_json
  end
end

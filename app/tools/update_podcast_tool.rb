# frozen_string_literal: true

class UpdatePodcastTool < AuthenticatedTool
  tool_name 'update_podcast'
  requires_permission :update, Podcast

  description <<~MD
    Edits a podcast by id. Only the fields you pass are touched. Previews unless
    confirm=true. To change part of the description, prefer `replacements`:
    `description` is the only field it patches, and it is matched as HTML.
  MD

  arguments do
    required(:id).filled(:integer).description('Numeric id of the podcast')
    optional(:title).filled(:string).description('Podcast title')
    optional(:description).filled(:string).description('Description; HTML is accepted')
    optional(:spotify_url).filled(:string).description('Spotify link')
    optional(:youtube_url).filled(:string).description('YouTube link')
    optional(:thumbnail_url).filled(:string).description('Cover image URL')
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = save')
    instance_exec(&ApplicationTool::REPLACEMENTS)
  end

  def call(id:, confirm: false, **fields)
    podcast = Podcast.find(id)
    PodcastWriteService.new(ability: ability, record: podcast, **fields).call(confirm: confirm).to_json
  rescue ActiveRecord::RecordNotFound
    { status: 'error', errors: ["No podcast with id #{id}"] }.to_json
  end
end

# frozen_string_literal: true

# Podcasts and their episodes: one tool, six operations.
class PodcastsTool < AuthenticatedTool
  tool_name 'podcasts'
  requires_permission :read, Podcast

  OPERATIONS = %w[list get create update create_episode update_episode].freeze

  description <<~MD
    Podcasts and their episodes. Descriptions are rich text: they come back as
    HTML and accept it.

    operation=list (default): podcasts with how many episodes each has and
    where it is published, filtered by query (title).
    operation=get: one podcast (`id`) with its description and every episode,
    newest first.
    operation=create: title and description are required. Episodes are added
    afterwards with create_episode.
    operation=update: edits podcast `id`; only the fields passed are touched.
    operation=create_episode: adds an episode to `podcast_id`; title,
    description, season, episode and released_at are required. It is created
    unpublished — not shown on the site — unless published=true; that is
    separate from released_at, when it came out on Spotify or YouTube. The
    preview warns if that season and number already exist in the podcast.
    operation=update_episode: edits episode `id`; only the fields passed are touched.

    To change part of a description, prefer `replacements` (description is the
    only field it patches, matched as HTML). Writes take two steps:
    confirm=false (the default) previews without saving.
  MD

  arguments do
    optional(:operation).filled(:string)
                        .description("'list' (default), 'get', 'create', 'update', 'create_episode' or 'update_episode'")
    optional(:id).filled(:integer).description('get/update: podcast id. update_episode: episode id')
    optional(:podcast_id).filled(:integer).description('create_episode: the podcast it belongs to')
    optional(:query).filled(:string).description('list: substring matched against the title')
    optional(:limit).filled(:integer).description("list: how many (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
    optional(:title).filled(:string).description('Podcast or episode title')
    optional(:description).filled(:string).description('Description; HTML is accepted')
    optional(:spotify_url).filled(:string).description('Spotify link')
    optional(:youtube_url).filled(:string).description('YouTube link')
    optional(:thumbnail_url).filled(:string).description('Cover image URL')
    optional(:season).filled(:integer).description('episodes: season number, 1 or more')
    optional(:episode).filled(:integer).description('episodes: number within the season, 1 or more')
    optional(:released_at).filled(:string).description('episodes: when it came out on Spotify / YouTube, YYYY-MM-DD')
    optional(:published).filled(:bool).description('episodes: shown on the site or not')
    optional(:confirm).filled(:bool).description('writes: false (default) = preview only; true = save')
    instance_exec(&ApplicationTool::REPLACEMENTS)
  end

  def call(operation: 'list', id: nil, podcast_id: nil, confirm: false, limit: DEFAULT_LIMIT, **fields)
    case operation
    when 'list' then list(limit: limit, query: fields[:query])
    when 'get' then get(Podcast.find(id.presence || raise(ActiveRecord::RecordNotFound)))
    when 'create' then write(Podcast, nil, confirm: confirm, **fields.except(:query))
    when 'update' then write(Podcast, Podcast.find(id.presence || raise(ActiveRecord::RecordNotFound)), confirm: confirm, **fields.except(:query))
    when 'create_episode' then write(Episode, Podcast.find(podcast_id).episodes.build, confirm: confirm, **fields.except(:query))
    when 'update_episode' then write(Episode, Episode.find(id.presence || raise(ActiveRecord::RecordNotFound)), confirm: confirm, **fields.except(:query))
    else unknown_operation(operation)
    end
  rescue ActiveRecord::RecordNotFound
    error(operation == 'create_episode' ? "No podcast with id #{podcast_id.inspect}" : "No #{operation.include?('episode') ? 'episode' : 'podcast'} with id #{id.inspect}")
  end

  private

  def list(limit:, query: nil)
    scope = Podcast.includes(:episodes).order(:title)
    scope = scope.where('title LIKE ?', "%#{query}%") if query.present?

    podcasts = scope.limit(limit.clamp(1, MAX_LIMIT)).map { |podcast| summary(podcast) }
    listing(:podcasts, podcasts, total: scope.count, narrow: 'query')
  end

  def summary(podcast)
    { id: podcast.id, title: podcast.title, episodes: podcast.episodes.size,
      spotify_url: podcast.spotify_url, youtube_url: podcast.youtube_url }
  end

  def get(podcast)
    { id: podcast.id, title: podcast.title, description: podcast.description_body,
      spotify_url: podcast.spotify_url, youtube_url: podcast.youtube_url,
      thumbnail_url: podcast.thumbnail_url,
      episodes: podcast.episodes.order(season: :desc, episode: :desc).map { |e| episode_summary(e) } }.to_json
  end

  def episode_summary(episode)
    { id: episode.id, season: episode.season, episode: episode.episode, title: episode.title,
      published: episode.published, released_at: episode.released_at, spotify_url: episode.spotify_url,
      youtube_url: episode.youtube_url }
  end

  # `record` is nil for a new podcast, a built episode for a new episode, or the one being edited.
  def write(model, record, confirm:, **fields)
    action = record&.persisted? ? :update : :create
    return unauthorized(action, model) unless ability.can?(action, model)

    service = model == Podcast ? PodcastWriteService : EpisodeWriteService
    service.new(ability: ability, record: record, **fields).call(confirm: confirm).to_json
  end
end

# frozen_string_literal: true

# News items — the short announcements with a date, a place and a link: one
# tool, four operations.
class NewsTool < AuthenticatedTool
  tool_name 'news'
  requires_permission :read, News

  OPERATIONS = %w[list get create update].freeze

  description <<~MD
    News items: the short announcements with a date, a place and a link. They
    have no slug; look them up by numeric id. Unlike articles, news carries no
    separate publishing permission.

    operation=list (default): newest event date first, filtered by query
    (title), lang, published.
    operation=get: one item in full.
    operation=create: title is required; unpublished unless published=true.
    operation=update: edits item `id`; only the fields passed are touched. To
    change part of the announcement, prefer `replacements` (description is the
    only field it patches).

    Writes take two steps: confirm=false (the default) previews without saving;
    call again with confirm=true once the user agrees.
  MD

  arguments do
    optional(:operation).filled(:string).description("'list' (default), 'get', 'create' or 'update'")
    optional(:id).filled(:integer).description('get/update: numeric id of the news item')
    optional(:query).filled(:string).description('list: substring matched against the title')
    optional(:lang).filled(:string).description("Language: 'es' or 'en' (list: filter; create: default es)")
    optional(:published).filled(:bool).description('list: filter. create/update: shown on the site or not')
    optional(:limit).filled(:integer).description("list: how many (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
    optional(:title).filled(:string).description('Headline')
    optional(:description).filled(:string).description('Body of the announcement')
    optional(:url).filled(:string).description('Link the item points at')
    optional(:event_date).filled(:string).description('Date of the event, YYYY-MM-DD')
    optional(:where).filled(:string).description('Where it happens')
    optional(:img).filled(:string).description('Image URL')
    optional(:video).filled(:string).description('Video URL')
    optional(:audio).filled(:string).description('Audio URL')
    optional(:confirm).filled(:bool).description('create/update: false (default) = preview only; true = save')
    instance_exec(&ApplicationTool::REPLACEMENTS)
  end

  def call(operation: 'list', id: nil, confirm: false, limit: DEFAULT_LIMIT, published: nil, **fields)
    case operation
    when 'list' then list(limit: limit, published: published, **fields.slice(:query, :lang))
    when 'get' then get(find(id))
    when 'create' then write(nil, confirm: confirm, published: published || false, **fields.except(:query))
    when 'update' then write(find(id), confirm: confirm, published: published, **fields.except(:query))
    else unknown_operation(operation)
    end
  rescue ActiveRecord::RecordNotFound
    error("No news item with id #{id.inspect}")
  end

  private

  def find(id)
    raise ActiveRecord::RecordNotFound if id.blank?

    News.find(id)
  end

  def list(limit:, query: nil, lang: nil, published: nil)
    scope = News.order(event_date: :desc, created_at: :desc)
    scope = scope.where('title LIKE ?', "%#{query}%") if query.present?
    scope = scope.where(lang: lang) if lang.present?
    scope = scope.where(published: published) unless published.nil?

    items = scope.limit(limit.clamp(1, MAX_LIMIT)).map { |item| summary(item) }
    listing(:news, items, total: scope.count, narrow: 'query, lang or published')
  end

  def summary(item)
    { id: item.id, title: item.title, lang: item.lang, published: item.published,
      event_date: item.event_date, where: item.where, url: item.url }
  end

  def get(item)
    { id: item.id, title: item.title, description: item.description, lang: item.lang,
      published: item.published, event_date: item.event_date, where: item.where, url: item.url,
      img: item.img, video: item.video, audio: item.audio,
      trainers: item.trainers.map(&:name), updated_at: item.updated_at }.to_json
  end

  def write(item, confirm:, published:, **fields)
    action = item ? :update : :create
    return unauthorized(action, News) unless ability.can?(action, News)

    NewsWriteService.new(ability: ability, record: item, published: published, **fields)
                    .call(confirm: confirm).to_json
  end
end

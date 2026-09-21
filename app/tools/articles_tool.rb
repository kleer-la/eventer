# frozen_string_literal: true

# Blog articles: one tool, four operations, so the connector lists one permission.
class ArticlesTool < AuthenticatedTool
  tool_name 'articles'
  requires_permission :read, Article

  OPERATIONS = %w[list get create update].freeze
  INDUSTRIES = 'finantial | technology | public_services | consumer_goods | energy'

  description <<~MD
    Blog articles.

    operation=list (default): summaries — id, slug, title, language, whether it
    is published, category, when it last changed substantively — most recently
    changed first, filtered by query, lang, published, category. Bodies are
    not included.
    operation=get: one article in full, body included, by id (slug or numeric).
    Read it before editing, so the change is made against the current text.
    operation=create: title, description and body are required; the slug is
    derived from the title when omitted; unpublished unless published=true.
    operation=update: edits article `id`; only the fields passed are touched.
    To change part of the body, prefer `replacements` (body is the only field
    it patches) over sending the whole body back.

    Writes take two steps: confirm=false (the default) validates and returns a
    preview without saving — show it to the user; call again with confirm=true
    only once they explicitly agree. Changing `published` needs publishing
    rights: a content user can edit but not publish, as in the admin screens.
  MD

  arguments do
    optional(:operation).filled(:string).description("'list' (default), 'get', 'create' or 'update'")
    optional(:id).filled(:string).description('get/update: article slug (preferred) or numeric id')
    optional(:query).filled(:string).description('list: substring matched against the title')
    optional(:lang).filled(:string).description("Language: 'es' or 'en' (list: filter; create: default es)")
    optional(:published).filled(:bool)
                        .description('list: filter. create/update: publish (or unpublish). Needs publishing rights')
    optional(:category).filled(:string).description('Category name (list: filter)')
    optional(:limit).filled(:integer).description("list: how many (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
    optional(:title).filled(:string).description('Article title')
    optional(:tabtitle).filled(:string).description('Browser tab / SEO title')
    optional(:description).filled(:string).description('Summary used for SEO, at most 160 characters')
    optional(:body).filled(:string).description('Full body. Changing it regenerates the spoken audio')
    optional(:slug).filled(:string).description('URL slug; derived from the title when omitted. ' \
                                                'Changing it keeps the old one redirecting')
    optional(:cover).filled(:string).description('Cover image URL')
    optional(:header).filled(:string).description('Header image URL')
    optional(:industry).filled(:string).description(INDUSTRIES)
    optional(:noindex).filled(:bool).description('true = ask search engines not to index it')
    optional(:selected).filled(:bool).description('true = feature it on the blog')
    optional(:confirm).filled(:bool).description('create/update: false (default) = preview only; true = save')
    instance_exec(&ApplicationTool::REPLACEMENTS)
  end

  LIST_FILTERS = %i[query lang published category].freeze

  def call(operation: 'list', id: nil, confirm: false, limit: DEFAULT_LIMIT, **fields)
    case operation
    when 'list' then list(limit: limit, **fields.slice(*LIST_FILTERS))
    when 'get' then get(find(id))
    when 'create' then write(nil, confirm: confirm, **fields)
    when 'update' then write(find(id), confirm: confirm, **fields)
    else unknown_operation(operation)
    end
  rescue ActiveRecord::RecordNotFound
    error("No article with slug or id #{id.inspect}")
  end

  private

  def find(id)
    raise ActiveRecord::RecordNotFound if id.blank?

    Article.friendly.find(id)
  end

  def list(limit:, query: nil, lang: nil, published: nil, category: nil)
    scope = Article.includes(:category).order(substantive_change_at: :desc, created_at: :desc)
    scope = scope.where('title LIKE ?', "%#{query}%") if query.present?
    scope = scope.where(lang: lang) if lang.present?
    scope = scope.where(published: published) unless published.nil?
    scope = scope.joins(:category).where(categories: { name: category }) if category.present?

    articles = scope.limit(limit.clamp(1, MAX_LIMIT)).map { |article| summary(article) }
    listing(:articles, articles, total: scope.count, narrow: 'query, lang, published or category')
  end

  def summary(article)
    { id: article.id, slug: article.slug, title: article.title, lang: article.lang,
      published: article.published, selected: article.selected, category: article.category_name,
      description: article.description, substantive_change_at: article.substantive_change_at }
  end

  def get(article)
    {
      id: article.id, slug: article.slug, title: article.title, tabtitle: article.tabtitle,
      lang: article.lang, published: article.published, selected: article.selected,
      noindex: article.noindex, industry: article.industry, category: article.category_name,
      description: article.description, cover: article.cover, header: article.header,
      body: article.body, trainers: article.trainers.map(&:name),
      substantive_change_at: article.substantive_change_at, updated_at: article.updated_at
    }.to_json
  end

  def write(article, confirm:, **fields)
    action = article ? :update : :create
    return unauthorized(action, Article) unless ability.can?(action, Article)

    ArticleWriteService.new(ability: ability, record: article, **fields.except(*LIST_FILTERS - %i[lang published category]))
                       .call(confirm: confirm).to_json
  end
end

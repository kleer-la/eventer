# frozen_string_literal: true

# Resources (books, infographics, canvases, guides, games, videos…): one tool,
# four operations, so the connector lists one permission.
class ResourcesTool < AuthenticatedTool
  tool_name 'resources'
  requires_permission :read, Resource

  OPERATIONS = %w[list get create update].freeze
  FORMATS = 'card | book | infographic | canvas | guide | game | assessment | video | other'

  description <<~MD
    Resources: books, infographics, canvases, guides, games, videos…

    operation=list (default): summaries — id, slug, both titles, format,
    whether it is published, category, whether it can be downloaded — filtered
    by query, format, published, category. Long texts are not included.
    operation=get: one resource in full — both languages, links, tags, credits
    and the contents it recommends — by id (slug or numeric). Read it before
    editing, so the change is made against what is actually there.
    operation=create: title_es, description_es and format are required; the
    slug is derived from the Spanish title when omitted; unpublished unless
    published=true. Only the Spanish side is required; an empty English side
    shows untranslated on the English site, and the preview says so.
    operation=update: edits resource `id`; only the fields passed are touched,
    and any text field but the Spanish title and description can be emptied
    with "". To change part of a long text, prefer `replacements` (it patches
    long_description_es/en and comments_es/en).

    Fields ending in _es and _en are the Spanish and English sides of the same
    thing. Writes take two steps: confirm=false (the default) validates and
    previews without saving; call again with confirm=true once the user agrees.
    Changing `published` needs publishing rights, as in the admin screens.
  MD

  arguments do
    optional(:operation).filled(:string).description("'list' (default), 'get', 'create' or 'update'")
    optional(:id).filled(:string).description('get/update: resource slug (preferred) or numeric id')
    optional(:query).filled(:string).description('list: substring matched against either title')
    optional(:format).filled(:string).description("#{FORMATS} (list: filter)")
    optional(:published).filled(:bool)
                        .description('list: filter. create/update: publish (or unpublish). Needs publishing rights')
    optional(:category).filled(:string).description('Category name (list: filter)')
    optional(:limit).filled(:integer).description("list: how many (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
    optional(:title_es).filled(:string).description('Spanish title, 2 to 100 characters')
    optional(:title_en).value(:string).description('English title')
    optional(:description_es).filled(:string).description('Spanish summary, at most 220 characters')
    optional(:description_en).value(:string).description('English summary')
    optional(:slug).filled(:string).description('URL slug; derived from the Spanish title when omitted')
    optional(:long_description_es).value(:string).description('Spanish long description')
    optional(:long_description_en).value(:string).description('English long description')
    optional(:comments_es).value(:string).description('Spanish notes shown on the page')
    optional(:comments_en).value(:string).description('English notes shown on the page')
    optional(:cover_es).value(:string).description('Spanish cover image URL')
    optional(:cover_en).value(:string).description('English cover image URL')
    optional(:getit_es).value(:string)
                       .description('Spanish download link. On the site it turns the page into a download form ' \
                                    '(name, email, reCAPTCHA) and the link is sent by email; the resource counts as ' \
                                    'downloadable. Leave it out for a page without the form')
    optional(:getit_en).value(:string).description('English download link (see getit_es)')
    optional(:buyit_es).value(:string).description('Spanish purchase link')
    optional(:buyit_en).value(:string).description('English purchase link')
    optional(:landing_es).value(:string)
                         .description("Spanish landing page URL. With no getit, the site shows a 'Más info' button " \
                                      'linking here; a youtu.be URL is embedded as a video instead')
    optional(:landing_en).value(:string).description('English landing page URL (see landing_es)')
    optional(:preview_es).value(:string).description('Spanish preview link')
    optional(:preview_en).value(:string).description('English preview link')
    optional(:share_text_es).value(:string).description('Spanish sharing text')
    optional(:share_text_en).value(:string).description('English sharing text')
    optional(:tags_es).value(:string).description('Spanish tags')
    optional(:tags_en).value(:string).description('English tags')
    optional(:seo_description_es).value(:string).description('Spanish SEO description')
    optional(:seo_description_en).value(:string).description('English SEO description')
    optional(:tabtitle_es).value(:string).description('Spanish browser tab title')
    optional(:tabtitle_en).value(:string).description('English browser tab title')
    optional(:confirm).filled(:bool).description('create/update: false (default) = preview only; true = save')
    instance_exec(&ApplicationTool::REPLACEMENTS)
  end

  LIST_FILTERS = %i[query format published category].freeze

  def call(operation: 'list', id: nil, confirm: false, limit: DEFAULT_LIMIT, **fields)
    case operation
    when 'list' then list(limit: limit, **fields.slice(*LIST_FILTERS))
    when 'get' then get(find(id))
    when 'create' then write(nil, confirm: confirm, **fields)
    when 'update' then write(find(id), confirm: confirm, **fields)
    else unknown_operation(operation)
    end
  rescue ActiveRecord::RecordNotFound
    error("No resource with slug or id #{id.inspect}")
  end

  private

  def find(id)
    raise ActiveRecord::RecordNotFound if id.blank?

    Resource.friendly.find(id)
  end

  def list(limit:, format: nil, **filters)
    return unknown_format(format) if format.present? && Resource.formats.exclude?(format)

    scope = filtered(Resource.includes(:category).order(updated_at: :desc), format: format, **filters)
    resources = scope.limit(limit.clamp(1, MAX_LIMIT)).map { |resource| summary(resource) }
    listing(:resources, resources, total: scope.count, narrow: 'query, format, published or category')
  end

  def filtered(scope, query: nil, format: nil, published: nil, category: nil)
    scope = scope.where('title_es LIKE :q OR title_en LIKE :q', q: "%#{query}%") if query.present?
    scope = scope.where(format: format) if format.present?
    scope = scope.where(published: published) unless published.nil?
    scope = scope.joins(:category).where(categories: { name: category }) if category.present?
    scope
  end

  def unknown_format(format)
    error("Unknown format #{format.inspect}. Valid ones: #{Resource.formats.keys.join(', ')}")
  end

  def summary(resource)
    { id: resource.id, slug: resource.slug, title_es: resource.title_es, title_en: resource.title_en,
      format: resource.format, published: resource.published, category: resource.category_name,
      downloadable: resource.downloadable, updated_at: resource.updated_at }
  end

  def get(resource)
    { id: resource.id, slug: resource.slug, format: resource.format, published: resource.published,
      category: resource.category_name, downloadable: resource.downloadable,
      es: side(resource, 'es'), en: side(resource, 'en'), updated_at: resource.updated_at }
      .merge(credits(resource))
      .merge(recommends: resource.recommended_contents.includes(:target).map { |content| recommendation(content) })
      .to_json
  end

  def credits(resource)
    { authors: resource.authors.map(&:name), translators: resource.translators.map(&:name),
      illustrators: resource.illustrators.map(&:name) }
  end

  def side(resource, lang)
    %w[title description long_description comments cover getit buyit landing preview
       share_text tags seo_description tabtitle].to_h do |field|
      [field, resource.public_send("#{field}_#{lang}")]
    end
  end

  def recommendation(content)
    { target_type: content.target_type, target_id: content.target_id,
      target: content.target&.try(:title) || content.target&.try(:name),
      relevance_order: content.relevance_order }
  end

  def write(resource, confirm:, **fields)
    action = resource ? :update : :create
    return unauthorized(action, Resource) unless ability.can?(action, Resource)

    ResourceWriteService.new(ability: ability, record: resource, **fields.except(:query))
                        .call(confirm: confirm).to_json
  end
end

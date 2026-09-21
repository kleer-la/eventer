# frozen_string_literal: true

# Site pages: one tool, four operations. A page is either an 'overlay' —
# section overrides for an existing static template, like home or contact — or
# a 'flagship', a standalone page rendered at /:lang/:slug.
class PagesTool < AuthenticatedTool
  tool_name 'pages'
  requires_permission :read, Page

  OPERATIONS = %w[list get create update].freeze

  description <<~MD
    Site pages. A page is either an 'overlay' — section overrides for an
    existing static template, like home or contact — or a 'flagship', a
    standalone page rendered at /:lang/:slug. Slugs are unique per language, so
    the same page exists once in Spanish and once in English; look pages up by
    numeric id.

    operation=list (default): filtered by query (name), lang, template.
    operation=get: one page with its sections in position order. Sections are
    read-only here: they are edited in the admin.
    operation=create: name and lang are required; the slug is derived from the
    name when omitted. The page is created without sections; a 'flagship' with
    no sections renders empty, and the preview says so.
    operation=update: edits page `id`; only the fields passed are touched.

    Writes take two steps: confirm=false (the default) previews without saving.
  MD

  arguments do
    optional(:operation).filled(:string).description("'list' (default), 'get', 'create' or 'update'")
    optional(:id).filled(:integer).description('get/update: numeric id of the page')
    optional(:query).filled(:string).description('list: substring matched against the name')
    optional(:lang).filled(:string).description("Language: 'es' or 'en' (list: filter; create: required)")
    optional(:template).filled(:string).description('overlay (default) | flagship (list: filter)')
    optional(:limit).filled(:integer).description("list: how many (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
    optional(:name).filled(:string).description('Page name')
    optional(:slug).filled(:string).description('URL slug, unique within the language')
    optional(:cover).filled(:string).description('Cover image URL')
    optional(:canonical).filled(:string).description('Canonical URL, if it points elsewhere')
    optional(:seo_title).filled(:string).description('SEO title')
    optional(:seo_description).filled(:string).description('SEO description')
    optional(:show_in_footer).filled(:bool).description('true = link it from the footer')
    optional(:noindex).filled(:bool)
                      .description('true = keep it out of search results. The page stays reachable at its URL')
    optional(:confirm).filled(:bool).description('create/update: false (default) = preview only; true = save')
  end

  def call(operation: 'list', id: nil, confirm: false, limit: DEFAULT_LIMIT, **fields)
    case operation
    when 'list' then list(limit: limit, **fields.slice(:query, :lang, :template))
    when 'get' then get(find(id))
    when 'create' then write(nil, confirm: confirm, **fields.except(:query))
    when 'update' then write(find(id), confirm: confirm, **fields.except(:query))
    else unknown_operation(operation)
    end
  rescue ActiveRecord::RecordNotFound
    error("No page with id #{id.inspect}")
  end

  private

  def find(id)
    raise ActiveRecord::RecordNotFound if id.blank?

    Page.find(id)
  end

  def list(limit:, query: nil, lang: nil, template: nil)
    return unknown_template(template) if template.present? && Page.templates.exclude?(template)

    scope = Page.includes(:sections).order(:lang, :name)
    scope = scope.where('name LIKE ?', "%#{query}%") if query.present?
    scope = scope.where(lang: lang) if lang.present?
    scope = scope.where(template: template) if template.present?

    pages = scope.limit(limit.clamp(1, MAX_LIMIT)).map { |page| summary(page) }
    listing(:pages, pages, total: scope.count, narrow: 'query, lang or template')
  end

  def unknown_template(template)
    error("Unknown template #{template.inspect}. Valid ones: #{Page.templates.keys.join(', ')}")
  end

  def summary(page)
    { id: page.id, slug: page.slug, name: page.name, lang: page.lang, template: page.template,
      sections: page.sections.size, show_in_footer: page.show_in_footer }
  end

  def get(page)
    { id: page.id, slug: page.slug, name: page.name, lang: page.lang, template: page.template,
      cover: page.cover, canonical: page.canonical, show_in_footer: page.show_in_footer,
      seo_title: page.seo_title, seo_description: page.seo_description,
      sections: page.sections.order(:position).map { |section| section_summary(section) },
      updated_at: page.updated_at }.to_json
  end

  def section_summary(section)
    { id: section.id, position: section.position, slug: section.slug, title: section.title,
      cta_text: section.cta_text, cta_url: section.cta_url, content: section.content }
  end

  def write(page, confirm:, **fields)
    action = page ? :update : :create
    return unauthorized(action, Page) unless ability.can?(action, Page)

    PageWriteService.new(ability: ability, record: page, **fields).call(confirm: confirm).to_json
  end
end

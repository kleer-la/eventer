# frozen_string_literal: true

class ListResourcesTool < AuthenticatedTool
  tool_name 'list_resources'
  requires_permission :read, Resource

  description <<~MD
    Lists resources (books, infographics, canvases, guides, games, videos…)
    with a summary of each: id, slug, both titles, format, whether it is
    published, category and whether it can be downloaded. Long texts are not
    included — use get_resource for one in full.
  MD

  arguments do
    optional(:query).filled(:string).description('Substring matched against either title')
    optional(:format).filled(:string)
                     .description('card | book | infographic | canvas | guide | game | assessment | video | other')
    optional(:published).filled(:bool).description('true = only published, false = only drafts')
    optional(:category).filled(:string).description('Category name')
    optional(:limit).filled(:integer).description("How many to return (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
  end

  def call(query: nil, format: nil, published: nil, category: nil, limit: DEFAULT_LIMIT)
    return unknown_format(format) if format.present? && Resource.formats.exclude?(format)

    scope = Resource.includes(:category).order(updated_at: :desc)
    scope = scope.where('title_es LIKE :q OR title_en LIKE :q', q: "%#{query}%") if query.present?
    scope = scope.where(format: format) if format.present?
    scope = scope.where(published: published) unless published.nil?
    scope = scope.joins(:category).where(categories: { name: category }) if category.present?

    resources = scope.limit(limit.clamp(1, MAX_LIMIT)).map { |resource| summary(resource) }
    listing(:resources, resources, total: scope.count, narrow: 'query, format, published or category')
  end

  private

  def unknown_format(format)
    { status: 'error',
      errors: ["Unknown format #{format.inspect}. Valid ones: #{Resource.formats.keys.join(', ')}"] }.to_json
  end

  def summary(resource)
    { id: resource.id, slug: resource.slug, title_es: resource.title_es, title_en: resource.title_en,
      format: resource.format, published: resource.published, category: resource.category_name,
      downloadable: resource.downloadable, updated_at: resource.updated_at }
  end
end

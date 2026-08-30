# frozen_string_literal: true

class ListPagesTool < AuthenticatedTool
  tool_name 'list_pages'
  requires_permission :read, Page

  description <<~MD
    Lists the site pages. A page is either an 'overlay' — section overrides for
    an existing static template, like home or contact — or a 'flagship', a
    standalone page rendered at /:lang/:slug. Slugs are unique per language, so
    the same page exists once in Spanish and once in English.
  MD

  arguments do
    optional(:query).filled(:string).description('Substring matched against the name')
    optional(:lang).filled(:string).description("Language: 'es' or 'en'")
    optional(:template).filled(:string).description('overlay | flagship')
  end

  def call(query: nil, lang: nil, template: nil)
    return unknown_template(template) if template.present? && Page.templates.exclude?(template)

    scope = Page.includes(:sections).order(:lang, :name)
    scope = scope.where('name LIKE ?', "%#{query}%") if query.present?
    scope = scope.where(lang: lang) if lang.present?
    scope = scope.where(template: template) if template.present?

    { count: scope.size, pages: scope.map { |page| summary(page) } }.to_json
  end

  private

  def unknown_template(template)
    { status: 'error',
      errors: ["Unknown template #{template.inspect}. Valid ones: #{Page.templates.keys.join(', ')}"] }.to_json
  end

  def summary(page)
    { id: page.id, slug: page.slug, name: page.name, lang: page.lang, template: page.template,
      sections: page.sections.size, show_in_footer: page.show_in_footer }
  end
end

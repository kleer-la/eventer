# frozen_string_literal: true

class GetPageTool < AuthenticatedTool
  tool_name 'get_page'
  requires_permission :read, Page

  description <<~MD
    Returns one page with its sections in position order, by id. Sections are
    read-only here: they are edited in the admin, not through this server.

    Slugs repeat across languages, so look pages up by id — list_pages gives you
    the right one.
  MD

  arguments do
    required(:id).filled(:integer).description('Numeric id of the page')
  end

  def call(id:)
    page = Page.find(id)
    { id: page.id, slug: page.slug, name: page.name, lang: page.lang, template: page.template,
      cover: page.cover, canonical: page.canonical, show_in_footer: page.show_in_footer,
      seo_title: page.seo_title, seo_description: page.seo_description,
      sections: page.sections.order(:position).map { |section| section_summary(section) },
      updated_at: page.updated_at }.to_json
  rescue ActiveRecord::RecordNotFound
    { status: 'error', errors: ["No page with id #{id}"] }.to_json
  end

  private

  def section_summary(section)
    { id: section.id, position: section.position, slug: section.slug, title: section.title,
      cta_text: section.cta_text, cta_url: section.cta_url, content: section.content }
  end
end

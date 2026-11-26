# frozen_string_literal: true

# What the website's template for an overlay page reads (kleer-la/eventer#243).
#
# website17 loads an overlay by its slug (the same in both languages; the home
# page has none) and its views read sections by slug. A section under any other
# slug is stored and served by the API but never shown. Which slugs each
# template reads is the website's to say: WebsitePageTemplates asks it.
#
# Three states: the website did not answer (nothing can be checked), it loads
# no overlay with this slug (none of its sections shows), or it does.
class OverlayTemplate
  # nil when the page is not an overlay
  def self.for(page)
    new(page.slug, WebsitePageTemplates.fetch) if page&.overlay?
  end

  def initialize(slug, catalog)
    @slug = slug
    @catalog = catalog
  end

  def available? = !@catalog.nil?
  def known? = available? && @catalog.key?(@slug)

  # slug => what the template does with it; nil unless known
  def sections = (@catalog[@slug] if known?)

  def reads?(section_slug) = known? && sections.key?(section_slug)

  # What to tell an editor about this template, if anything.
  def note
    return "Could not read the website's page templates (#{WebsitePageTemplates.url}): sections not checked." \
      unless available?
    return "The website does not load an overlay with slug #{@slug.inspect}: no section of it shows." unless known?
    return if sections.any?

    'This template reads no section: only the SEO fields and the cover. Its headings are fixed ' \
      'in website17, so changing them needs a change there.'
  end
end

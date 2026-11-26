# frozen_string_literal: true

# Which sections each overlay page's template reads on the site, and what for.
#
# website17 loads an overlay by its slug (`Page.load_from_keventer(lang, slug)`,
# the same slug in both languages; the home page has none) and its views read
# sections by slug. A section under any other slug is stored and served by the
# API but never shown, and nothing said so until now (#243).
#
# This mirrors website17's views (controllers/*_controller.rb and the views they
# render, read at 471c0b98): change it when a template there starts or stops
# reading a section. Slugs whose view is commented out or switched off, like the
# home page's `recommended`, `agenda` and `academia`, are left out on purpose.
class OverlayTemplate
  SECTIONS = {
    nil => {
      'hero' => 'Home hero: title is the H1 (one line per row), content the text under it, cta_text the button',
      'banner' => 'Banner under the hero: title, cta_text, and content as a JSON object with ' \
                  'text, image, colours and cta_url',
      'services' => 'Heading (title) and intro (content) of the service areas block',
      'institutional' => 'Institutional block: title (one line per row), content, and cta_text as the URL ' \
                         'of a YouTube embed or an image',
      'clients' => 'Clients block: title, content and cta_text',
      'contact' => 'Closing contact banner: title, content, cta_text and cta_url'
    },
    'novedades' => {
      'hero' => 'Title is the H1 of the news page, content the subtitle under it'
    },
    'agenda' => {
      'agenda' => 'Title of the course schedule (only the title is read)',
      'empty_banner' => 'Shown when no course is scheduled: title and content',
      'empty_academia' => 'Shown when no course is scheduled: the Academia card (title, content, cta_text)',
      'empty_catalog' => 'Shown when no course is scheduled: the catalogue card (title, content, cta_text)'
    },
    'services-landing' => {
      'banner' => 'Top banner of the services page: title, content and cta_text',
      'intro' => 'Intro of the areas block: title, content and cta_text',
      'contact' => 'Closing contact banner: title, content and cta_text'
    },
    'service-area' => {
      'hero' => 'Default hero of every service area and service page (title, content, cta_text), ' \
                'where the area or service has no text of its own',
      'contact' => 'Default closing contact banner of every service area and service page'
    },
    'clientes' => {
      'clients' => 'Clients block: title, content and cta_text'
    },
    # These templates read only the page's SEO fields and cover.
    'recursos' => {}, 'blog' => {}, 'somos' => {}, 'podcasts' => {}, 'catalogo' => {},
    'llms' => {}
  }.freeze

  # nil when the page is not an overlay, or website17 loads no overlay by its slug.
  def self.for(page)
    return unless page&.overlay? && SECTIONS.key?(page.slug)

    new(page.slug)
  end

  def self.unknown?(page) = page&.overlay? && !SECTIONS.key?(page.slug)

  def initialize(slug)
    @slug = slug
  end

  # slug => what the template does with it
  def sections = SECTIONS.fetch(@slug)

  def reads?(section_slug) = sections.key?(section_slug)

  def note
    return if sections.any?

    'This template reads no section: only the SEO fields and the cover. Its headings are fixed ' \
      'in website17, so changing them needs a change there.'
  end
end

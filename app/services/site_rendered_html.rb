# frozen_string_literal: true

# What of a rich-text block the site will not show. Keventer stores the HTML as
# given, but the API serves it rendered by ActionText (body.to_s), whose
# sanitizer keeps a safe list of tags and attributes: inline styles, data-*,
# iframes and tables, among others, are dropped there, after a save that
# reported nothing (MCP suggestion #8 in QA).
#
# Compares the elements and attributes of the HTML given with those of its
# rendering. Set-based: a tag or attribute counts as kept if it survives
# anywhere in the rendering.
class SiteRenderedHtml
  def initialize(html)
    @given = Nokogiri::HTML5.fragment(html.to_s)
    @rendered = Nokogiri::HTML5.fragment(ActionText::Content.new(html.to_s).to_s)
    # ActionText's layout wraps every rendering in <div class="trix-content">.
    @rendered.at_css('div.trix-content')&.then { |layout| layout.replace(layout.children) }
  end

  # e.g. ["<iframe>", "style (on hr, div)"]; empty when everything is shown
  def dropped = dropped_tags.map { |tag| "<#{tag}>" } + dropped_attributes

  private

  def dropped_tags = @dropped_tags ||= (tags(@given) - tags(@rendered)).sort

  def dropped_attributes
    kept = attribute_pairs(@rendered)
    lost = attribute_pairs(@given).reject { |pair| kept.include?(pair) || dropped_tags.include?(pair.first) }
    lost.group_by(&:last).sort.map { |attribute, pairs| "#{attribute} (on #{pairs.map(&:first).uniq.join(', ')})" }
  end

  def tags(fragment) = fragment.css('*').map(&:name).uniq

  def attribute_pairs(fragment)
    fragment.css('*').flat_map { |node| node.attribute_nodes.map { |attribute| [node.name, attribute.name] } }.uniq
  end
end

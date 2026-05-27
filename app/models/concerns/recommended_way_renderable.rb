# frozen_string_literal: true

# Renders the "Forma Recomendada" summary/details fields to HTML.
# Authors write HTML-first content (raw HTML is allowed, filter_html: false);
# Markdown still works for simple text. hard_wrap is off so multi-line HTML
# authoring is predictable (single newlines are not turned into <br>).
module RecommendedWayRenderable
  extend ActiveSupport::Concern

  def recommended_way_summary_html
    render_recommended_way_markdown(recommended_way_summary)
  end

  def recommended_way_details_html
    render_recommended_way_markdown(recommended_way_details)
  end

  private

  def render_recommended_way_markdown(source)
    return nil if source.blank?

    markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(hard_wrap: false, filter_html: false),
      tables: true,
      autolink: true,
      fenced_code_blocks: true,
      strikethrough: true
    )
    markdown.render(source)
  end
end

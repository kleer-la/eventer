# frozen_string_literal: true

module ApplicationHelper
  def link_to_menu_item(tag, name, url, options = nil)
    content_tag(tag, class: (current_page?(url) ? 'selected' : '')) do
      link_to name, url, options
    end
  end

  def menu_item_class(active, menu)
    if !active.nil? && active == menu
      'active'
    else
      ''
    end
  end

  def markdown(text)
    return '' if text.nil?

    renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
    renderer.render(text).html_safe
  end
end

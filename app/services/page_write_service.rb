# frozen_string_literal: true

class PageWriteService < ContentWriteService
  self.model = Page
  self.editable_fields = %i[name lang slug template cover canonical
                            seo_title seo_description show_in_footer noindex]
  # A page is reachable as soon as it has a slug; there is no visibility flag.
  self.publication_flag = nil

  private

  def model_warnings
    [template_warning, noindex_warning, empty_flagship_warning].compact
  end

  # Pages are created without sections, and a flagship has nothing else to show.
  def empty_flagship_warning
    return unless @record.new_record? && @record.flagship?

    'A flagship renders empty until it has sections: add them with operation=create_section.'
  end

  def template_warning
    return unless @record.changed.include?('template')

    'Changing the template changes how the whole page is rendered; check it before publishing links to it.'
  end

  def noindex_warning
    return unless @record.persisted? && @record.changed.include?('noindex')

    if @record.noindex
      'noindex on: the page leaves the sitemap and search results (it stays reachable at its URL).'
    else
      'noindex off: the page enters the sitemap and search results. Check the other language too.'
    end
  end
end

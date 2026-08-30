# frozen_string_literal: true

class PageWriteService < ContentWriteService
  self.model = Page
  self.editable_fields = %i[name lang slug template cover canonical
                            seo_title seo_description show_in_footer]
  # A page is reachable as soon as it has a slug; there is no visibility flag.
  self.publication_flag = nil

  private

  def model_warnings
    return [] unless @record.changed.include?('template')

    ['Changing the template changes how the whole page is rendered; check it before publishing links to it.']
  end
end

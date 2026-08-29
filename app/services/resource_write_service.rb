# frozen_string_literal: true

class ResourceWriteService < ContentWriteService
  self.model = Resource
  self.editable_fields = %i[title_es title_en description_es description_en format slug
                            long_description_es long_description_en comments_es comments_en
                            cover_es cover_en getit_es getit_en buyit_es buyit_en
                            landing_es landing_en preview_es preview_en
                            share_text_es share_text_en tags_es tags_en
                            seo_description_es seo_description_en tabtitle_es tabtitle_en]
  self.long_fields = %w[long_description_es long_description_en comments_es comments_en]

  private

  def model_warnings
    return [] if @record.title_en.present? || @record.description_en.present?

    ['Only the Spanish side is filled in: the resource will show untranslated in the English site.']
  end
end

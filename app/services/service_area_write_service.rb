# frozen_string_literal: true

class ServiceAreaWriteService < ContentWriteService
  self.model = ServiceArea
  self.editable_fields = %i[name slug icon primary_color secondary_color primary_font_color secondary_font_color
                            lang is_training_program summary cta_message side_image slogan subtitle description
                            target_title target value_proposition_title value_proposition ordering
                            seo_title seo_description
                            recommended_way_title recommended_way_note
                            recommended_way_summary recommended_way_details]
  self.rich_text_fields = %i[summary cta_message slogan subtitle description target value_proposition]
  self.long_fields = %w[recommended_way_summary recommended_way_details]
  self.publication_flag = :visible
  self.guarded_publication = false

  def initialize(visible: nil, **args)
    super(published: visible, **args)
  end
end

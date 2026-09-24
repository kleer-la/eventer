# frozen_string_literal: true

class ServiceAreaWriteService < ContentWriteService
  self.model = ServiceArea
  self.editable_fields = %i[name slug icon primary_color secondary_color primary_font_color secondary_font_color
                            lang is_training_program summary cta_message side_image slogan subtitle description
                            target_title target value_proposition_title value_proposition ordering
                            outcomes definitions program faq pricing brochure
                            hero_cta_text hero_secondary_cta_text hero_secondary_cta_target hero_note
                            contact_title contact_cta_text
                            seo_title seo_description
                            recommended_way_title recommended_way_note
                            recommended_way_summary recommended_way_details]
  self.rich_text_fields = %i[summary cta_message slogan subtitle description target value_proposition
                             outcomes definitions program faq]
  self.long_fields = %w[recommended_way_summary recommended_way_details]
  self.publication_flag = :visible
  self.guarded_publication = false

  def initialize(visible: nil, **args)
    super(published: visible, **args)
  end
end

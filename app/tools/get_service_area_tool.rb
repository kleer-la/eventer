# frozen_string_literal: true

class GetServiceAreaTool < AuthenticatedTool
  tool_name 'get_service_area'
  requires_permission :read, ServiceArea

  description <<~MD
    Returns one service area in full, by slug or id: the rich-text blocks that
    make up its page (summary, slogan, subtitle, description, target, value
    proposition, CTA message), its palette and icon, the recommended-way copy,
    and the services listed under it. Rich text comes back as HTML.
  MD

  arguments do
    required(:id).filled(:string).description('Service area slug (preferred) or numeric id')
  end

  def call(id:)
    area = ServiceArea.friendly.find(id)
    { id: area.id, slug: area.slug, name: area.name, lang: area.lang, visible: area.visible,
      is_training_program: area.is_training_program, ordering: area.ordering,
      icon: area.icon, side_image: area.side_image,
      primary_color: area.primary_color, secondary_color: area.secondary_color,
      primary_font_color: area.primary_font_color, secondary_font_color: area.secondary_font_color,
      target_title: area.target_title, value_proposition_title: area.value_proposition_title,
      seo_title: area.seo_title, seo_description: area.seo_description,
      blocks: %i[summary cta_message slogan subtitle description target value_proposition]
              .index_with { |field| area.public_send(field).body.to_s },
      recommended_way: { title: area.recommended_way_title, note: area.recommended_way_note,
                         summary: area.recommended_way_summary, details: area.recommended_way_details },
      services: area.services.order(:ordering).map do |service|
        { id: service.id, slug: service.slug,
          name: service.name }
      end }.to_json
  rescue ActiveRecord::RecordNotFound
    { status: 'error', errors: ["No service area with slug or id #{id.inspect}"] }.to_json
  end
end

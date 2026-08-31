# frozen_string_literal: true

class GetServiceTool < AuthenticatedTool
  tool_name 'get_service'
  requires_permission :read, Service

  description <<~MD
    Returns one service in full, by slug or id: the rich-text blocks that make
    up its page (value proposition, outcomes, definitions, program, target,
    FAQ), the recommended-way copy, and what it recommends. Rich text comes back
    as HTML.
  MD

  arguments do
    required(:id).filled(:string).description('Service slug (preferred) or numeric id')
  end

  def call(id:)
    service = Service.friendly.find(id)
    { id: service.id, slug: service.slug, name: service.name, subtitle: service.subtitle,
      service_area: service.service_area&.name, published: service.published, ordering: service.ordering,
      card_description: service.card_description, pricing: service.pricing,
      side_image: service.side_image, brochure: service.brochure,
      seo_title: service.seo_title, seo_description: service.seo_description,
      blocks: %i[value_proposition outcomes definitions program target faq]
              .index_with { |field| service.public_send(field).body.to_s },
      recommended_way: { title: service.recommended_way_title, note: service.recommended_way_note,
                         summary: service.recommended_way_summary, details: service.recommended_way_details },
      recommends: service.recommended_contents.includes(:target).map do |content|
        { target_type: content.target_type, target_id: content.target_id,
          target: content.target&.try(:title) || content.target&.try(:name),
          relevance_order: content.relevance_order }
      end }.to_json
  rescue ActiveRecord::RecordNotFound
    { status: 'error', errors: ["No service with slug or id #{id.inspect}"] }.to_json
  end
end

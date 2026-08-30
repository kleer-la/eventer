# frozen_string_literal: true

class ListRecommendationsTool < AuthenticatedTool
  tool_name 'list_recommendations'
  requires_permission :read, RecommendedContent

  description <<~MD
    Shows what one entity recommends: the cross references an article,
    resource, service, event type or page points at, in relevance order.

    Relevance also decides the level shown to the reader: under 100 is
    'initial', 100 to 199 'intermediate', 200 and up 'advanced'.
  MD

  arguments do
    required(:source_type).filled(:string).description('Article | Resource | EventType | Service | Page')
    required(:source_id).filled(:string).description('Slug, numeric id, or the name/title of the entity')
  end

  def call(source_type:, source_id:)
    RecommendationService.new(ability: ability, source_type: source_type, source_id: source_id).list.to_json
  end
end

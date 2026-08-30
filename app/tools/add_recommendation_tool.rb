# frozen_string_literal: true

class AddRecommendationTool < AuthenticatedTool
  tool_name 'add_recommendation'
  requires_permission :update, RecommendedContent

  description <<~MD
    Makes one entity recommend another — an article pointing at a resource, a
    service at an event type, and so on. Pointing at something already
    recommended changes its relevance order instead of duplicating it.

    Relevance order decides both the order shown and the level: under 100 is
    'initial', 100 to 199 'intermediate', 200 and up 'advanced'. It defaults
    to 50 and has to be at least 1.

    Two steps: confirm=false (the default) previews without saving. Editing
    recommendations counts as editing the source, so it needs permission to
    update that source — recommending from a Service, for instance, is beyond
    what a content user may do.
  MD

  arguments do
    required(:source_type).filled(:string).description('Article | Resource | EventType | Service | Page')
    required(:source_id).filled(:string).description('Slug, numeric id, or name/title of the recommending entity')
    required(:target_type).filled(:string).description('Article | Resource | EventType | Service')
    required(:target_id).filled(:string).description('Slug, numeric id, or name/title of the recommended entity')
    optional(:relevance_order).filled(:integer).description('Order and level; 1 or more, defaults to 50')
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = save')
  end

  def call(source_type:, source_id:, target_type:, target_id:, relevance_order: nil, confirm: false)
    service = RecommendationService.new(ability: ability, source_type: source_type, source_id: source_id)
    service.add(target_type: target_type, target_id: target_id, confirm: confirm,
                **{ relevance_order: relevance_order }.compact).to_json
  end
end

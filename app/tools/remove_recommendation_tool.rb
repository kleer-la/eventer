# frozen_string_literal: true

class RemoveRecommendationTool < AuthenticatedTool
  tool_name 'remove_recommendation'
  requires_permission :update, RecommendedContent

  description <<~MD
    Stops one entity from recommending another. Only the cross reference goes
    away; neither entity is touched.

    Two steps: confirm=false (the default) says what would be removed without
    removing it. Like adding, it needs permission to update the source.
  MD

  arguments do
    required(:source_type).filled(:string).description('Article | Resource | EventType | Service | Page')
    required(:source_id).filled(:string).description('Slug, numeric id, or name/title of the recommending entity')
    required(:target_type).filled(:string).description('Article | Resource | EventType | Service | Page')
    required(:target_id).filled(:string).description('Slug, numeric id, or name/title of the recommended entity')
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = remove')
  end

  def call(source_type:, source_id:, target_type:, target_id:, confirm: false)
    RecommendationService.new(ability: ability, source_type: source_type, source_id: source_id)
                         .remove(target_type: target_type, target_id: target_id, confirm: confirm).to_json
  end
end

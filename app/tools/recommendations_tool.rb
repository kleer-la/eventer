# frozen_string_literal: true

# Cross references between contents — what an article, resource, service, area,
# course type or page recommends: one tool, three operations.
class RecommendationsTool < AuthenticatedTool
  tool_name 'recommendations'
  requires_permission :read, RecommendedContent

  OPERATIONS = %w[list add remove].freeze

  description <<~MD
    What one entity recommends: the cross references an article, resource,
    service, course type or page points at, in relevance order. Relevance
    decides both the order shown and the level the reader sees: under 100 is
    'initial', 100 to 199 'intermediate', 200 and up 'advanced'.

    operation=list (default): what source_type/source_id recommends.
    operation=add: makes the source recommend target_type/target_id. Pointing
    at something already recommended changes its relevance order instead of
    duplicating it; relevance_order defaults to 50 and has to be at least 1.
    operation=remove: stops the source from recommending the target. Only the
    cross reference goes away; neither entity is touched.

    Writes take two steps: confirm=false (the default) previews without saving.
    Editing recommendations counts as editing the source, so it needs
    permission to update that source — recommending from a Service, for
    instance, is beyond what a content user may do.
  MD

  arguments do
    optional(:operation).filled(:string).description("'list' (default), 'add' or 'remove'")
    required(:source_type).filled(:string).description('Article | Resource | EventType | Service | ServiceArea | Page')
    required(:source_id).filled(:string).description('Slug, numeric id, or name/title of the recommending entity')
    optional(:target_type).filled(:string).description('add/remove: Article | Resource | EventType | Service | Page')
    optional(:target_id).filled(:string).description('add/remove: slug, id, or name/title of the recommended entity')
    optional(:relevance_order).filled(:integer).description('add: order and level; 1 or more, defaults to 50')
    optional(:confirm).filled(:bool).description('add/remove: false (default) = preview only; true = save')
  end

  def call(source_type:, source_id:, operation: 'list', **args)
    return unknown_operation(operation) unless OPERATIONS.include?(operation)

    service = RecommendationService.new(ability: ability, source_type: source_type, source_id: source_id)
    return service.list.to_json if operation == 'list'
    return unauthorized(:update, RecommendedContent) unless ability.can?(:update, RecommendedContent)

    operation == 'add' ? add(service, **args) : remove(service, **args)
  end

  private

  def add(service, target_type: nil, target_id: nil, relevance_order: nil, confirm: false)
    service.add(target_type: target_type, target_id: target_id, confirm: confirm,
                **{ relevance_order: relevance_order }.compact).to_json
  end

  def remove(service, target_type: nil, target_id: nil, confirm: false, **)
    service.remove(target_type: target_type, target_id: target_id, confirm: confirm).to_json
  end
end

# frozen_string_literal: true

class ListServiceAreasTool < AuthenticatedTool
  tool_name 'list_service_areas'
  requires_permission :read, ServiceArea

  description <<~MD
    Lists service areas in display order. Long texts are not included — use
    get_service_area for one in full.
  MD

  arguments do
    optional(:query).filled(:string).description('Substring matched against the name')
    optional(:visible).filled(:bool).description('true = only visible, false = only hidden')
    optional(:limit).filled(:integer).description("How many to return (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
  end

  def call(query: nil, visible: nil, limit: DEFAULT_LIMIT)
    scope = ServiceArea.order(:ordering, :name)
    scope = scope.where('name LIKE ?', "%#{query}%") if query.present?
    scope = scope.where(visible: visible) unless visible.nil?

    areas = scope.limit(limit.clamp(1, MAX_LIMIT)).map { |area| summary(area) }
    listing(:service_areas, areas, total: scope.count, narrow: 'query or visible')
  end

  private

  def summary(area)
    { id: area.id, slug: area.slug, name: area.name, lang: area.lang, visible: area.visible,
      ordering: area.ordering }
  end
end

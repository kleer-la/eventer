# frozen_string_literal: true

class ListServicesTool < AuthenticatedTool
  tool_name 'list_services'
  requires_permission :read, Service

  description <<~MD
    Lists the services offered, grouped by service area and in display order.
    Long texts are not included — use get_service for one in full.
  MD

  arguments do
    optional(:query).filled(:string).description('Substring matched against the name')
    optional(:service_area).filled(:string).description('Service area name')
    optional(:visible).filled(:bool).description('true = only visible, false = only hidden')
  end

  def call(query: nil, service_area: nil, visible: nil)
    scope = Service.includes(:service_area).order(:ordering, :name)
    scope = scope.where('name LIKE ?', "%#{query}%") if query.present?
    scope = scope.joins(:service_area).where(service_areas: { name: service_area }) if service_area.present?
    scope = scope.where(visible: visible) unless visible.nil?

    { count: scope.size, services: scope.map { |service| summary(service) } }.to_json
  end

  private

  def summary(service)
    { id: service.id, slug: service.slug, name: service.name, subtitle: service.subtitle,
      service_area: service.service_area&.name, visible: service.visible, ordering: service.ordering }
  end
end

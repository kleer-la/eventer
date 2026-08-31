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
    optional(:published).filled(:bool).description('true = only published, false = only unpublished')
    optional(:limit).filled(:integer).description("How many to return (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
  end

  def call(query: nil, service_area: nil, published: nil, limit: DEFAULT_LIMIT)
    scope = Service.includes(:service_area).order(:ordering, :name)
    scope = scope.where('name LIKE ?', "%#{query}%") if query.present?
    scope = scope.joins(:service_area).where(service_areas: { name: service_area }) if service_area.present?
    scope = scope.where(published: published) unless published.nil?

    services = scope.limit(limit.clamp(1, MAX_LIMIT)).map { |service| summary(service) }
    listing(:services, services, total: scope.count, narrow: 'query, service_area or published')
  end

  private

  def summary(service)
    { id: service.id, slug: service.slug, name: service.name, subtitle: service.subtitle,
      service_area: service.service_area&.name, published: service.published, ordering: service.ordering }
  end
end

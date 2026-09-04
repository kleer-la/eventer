# frozen_string_literal: true

class ListEventTypesTool < AuthenticatedTool
  tool_name 'list_event_types'
  requires_permission :read, EventType

  description <<~MD
    Lists course types — the template a course is given from, and what a
    certificate names. Use it to find the id an event needs, and to check
    whether the course already exists before creating a new type for it.
  MD

  arguments do
    optional(:query).filled(:string).description('Substring matched against the name')
    optional(:lang).filled(:string).description("Language: 'es' or 'en'")
    optional(:in_catalog).filled(:bool).description('true = only the ones on sale on the site')
    optional(:limit).filled(:integer).description("How many to return (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
  end

  def call(query: nil, lang: nil, in_catalog: nil, limit: DEFAULT_LIMIT)
    scope = EventType.includes(:trainers).order(:name)
    scope = scope.where('name LIKE ?', "%#{query}%") if query.present?
    scope = scope.where(lang: lang) if lang.present?
    scope = scope.where(include_in_catalog: in_catalog) unless in_catalog.nil?

    types = scope.limit(limit.clamp(1, MAX_LIMIT)).map { |type| summary(type) }
    listing(:event_types, types, total: scope.count, narrow: 'query, lang or in_catalog')
  end

  private

  def summary(type)
    { id: type.id, name: type.name, lang: type.lang, duration: type.duration,
      include_in_catalog: type.include_in_catalog, is_kleer_certification: type.is_kleer_certification,
      trainers: type.trainers.map(&:name) }
  end
end

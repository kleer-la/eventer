# frozen_string_literal: true

class ListEventsTool < AuthenticatedTool
  tool_name 'list_events'
  requires_permission :read, Event

  description <<~MD
    Lists events — a course actually given on a date, in a place, by a trainer.
    Use it to find the id create_participant needs, and to check whether the
    course was already loaded before creating it again.

    Most recent first.
  MD

  arguments do
    optional(:query).filled(:string).description('Substring matched against the course type name or the city')
    optional(:event_type_id).filled(:integer).description('Only events of this course type')
    optional(:from).filled(:string).description('Only events on or after this date, YYYY-MM-DD')
    optional(:to).filled(:string).description('Only events on or before this date, YYYY-MM-DD')
    optional(:limit).filled(:integer).description("How many to return (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
  end

  def call(query: nil, event_type_id: nil, from: nil, to: nil, limit: DEFAULT_LIMIT)
    scope = filtered(query, event_type_id, from, to)
    events = scope.limit(limit.clamp(1, MAX_LIMIT)).map { |event| summary(event) }
    listing(:events, events, total: scope.count, narrow: 'query, event_type_id, from or to')
  rescue Date::Error => e
    { status: 'error', errors: ["#{e.message}. Dates go as YYYY-MM-DD."] }.to_json
  end

  private

  def filtered(query, event_type_id, from, to)
    scope = Event.includes(:event_type, :country, :trainer, :participants).order(date: :desc)
    if query.present?
      scope = scope.joins(:event_type)
                   .where('event_types.name LIKE :t OR events.city LIKE :t', t: "%#{query}%")
    end
    scope = scope.where(event_type_id: event_type_id) if event_type_id.present?
    scope = scope.where(date: Date.parse(from)..) if from.present?
    scope = scope.where(date: ..Date.parse(to)) if to.present?
    scope
  end

  def summary(event)
    { id: event.id, event_type: event.event_type&.name, date: event.date, city: event.city,
      country: event.country&.name, mode: event.mode, visibility_type: event.visibility_type,
      trainer: event.trainer&.name, participants: event.participants.size }
  end
end

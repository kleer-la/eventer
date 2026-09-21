# frozen_string_literal: true

# Events — a course actually given on a date, in a place, by a trainer: one
# tool, two operations.
class EventsTool < AuthenticatedTool
  tool_name 'events'
  requires_permission :read, Event

  OPERATIONS = %w[list create].freeze

  description <<~MD
    Events: a course actually given on a date, in a place, by a trainer.
    Participants hang off an event, and a certificate takes its date and place
    from it.

    operation=list (default): most recent first, filtered by query (course
    type name or city), event_type_id, from, to. Use it to find the id a
    participant needs, and to check whether the course was already loaded.
    operation=create: needs event_type_id, date, country, trainer, city, place
    and address. A past date is fine — loading a course already given is what
    this is for. Created private ("pr") and free unless you say otherwise, so
    it does not show up on the site or take registrations.

    Writes take two steps: confirm=false (the default) validates and returns a
    preview without saving; call again with confirm=true once the user agrees.
  MD

  arguments do
    optional(:operation).filled(:string).description("'list' (default) or 'create'")
    optional(:query).filled(:string).description('list: substring matched against the course type name or the city')
    optional(:event_type_id).filled(:integer).description('Course type id, from event_types (list: filter)')
    optional(:from).filled(:string).description('list: only events on or after this date, YYYY-MM-DD')
    optional(:to).filled(:string).description('list: only events on or before this date, YYYY-MM-DD')
    optional(:limit).filled(:integer).description("list: how many (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
    optional(:date).filled(:string).description('Start date, YYYY-MM-DD')
    optional(:country).filled(:string).description("Country name ('Argentina') or ISO code ('AR')")
    optional(:trainer).filled(:string).description('Trainer name, exactly as it is in the admin')
    optional(:trainer2).filled(:string).description('Second trainer name')
    optional(:city).filled(:string).description('City it was given in')
    optional(:place).filled(:string).description("Venue ('Oficinas del cliente', 'Zoom')")
    optional(:address).filled(:string).description('Address')
    optional(:mode).filled(:string).description('cl = classroom (default), ol = online, bl = blended')
    optional(:time_zone_name).filled(:string)
                             .description('Required when mode is ol, e.g. America/Argentina/Buenos_Aires')
    optional(:duration).filled(:integer).description('Days it ran (defaults to 1)')
    optional(:finish_date).filled(:string).description('End date, YYYY-MM-DD')
    optional(:start_time).filled(:string).description('Start of the day (defaults to 9:00)')
    optional(:end_time).filled(:string).description('End of the day (defaults to 18:00)')
    optional(:capacity).filled(:integer).description('Seats (defaults to 20)')
    optional(:list_price).filled(:float).description('List price (defaults to 0)')
    optional(:currency_iso_code).filled(:string).description("Currency, e.g. 'ARS', 'USD'")
    optional(:visibility_type).filled(:string)
                              .description('pr = private (default), pu = public, co = community. ' \
                                           'Public puts it on the site')
    optional(:confirm).filled(:bool).description('create: false (default) = preview only; true = save')
  end

  def call(operation: 'list', confirm: false, limit: DEFAULT_LIMIT, **fields)
    case operation
    when 'list' then list(limit: limit, **fields.slice(:query, :event_type_id, :from, :to))
    when 'create' then create(confirm: confirm, **fields.except(:query, :from, :to))
    else unknown_operation(operation)
    end
  end

  private

  def list(limit:, query: nil, event_type_id: nil, from: nil, to: nil)
    scope = filtered(query, event_type_id, from, to)
    events = scope.limit(limit.clamp(1, MAX_LIMIT)).map { |event| summary(event) }
    listing(:events, events, total: scope.count, narrow: 'query, event_type_id, from or to')
  rescue Date::Error => e
    error("#{e.message}. Dates go as YYYY-MM-DD.")
  end

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

  def create(confirm:, **fields)
    return unauthorized(:create, Event) unless ability.can?(:create, Event)

    EventWriteService.new(ability: ability, **fields).call(confirm: confirm).to_json
  end
end

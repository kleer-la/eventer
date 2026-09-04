# frozen_string_literal: true

class CreateEventTool < AuthenticatedTool
  tool_name 'create_event'
  requires_permission :create, Event

  description <<~MD
    Creates an event: one delivery of a course type, on a date, which
    participants hang off and the certificate takes its date and place from.

    A past date is fine — loading a course already given is what this is for.
    It is created private ("pr") and free unless you say otherwise, so it does
    not show up on the site or take registrations.

    Two steps: confirm=false (the default) validates and returns a preview
    without saving; call again with confirm=true once the user agrees.
  MD

  arguments do
    required(:event_type_id).filled(:integer).description('Course type id, from list_event_types')
    required(:date).filled(:string).description('Start date, YYYY-MM-DD')
    required(:country).filled(:string).description("Country name ('Argentina') or ISO code ('AR')")
    required(:trainer).filled(:string).description('Trainer name, exactly as it is in the admin')
    required(:city).filled(:string).description('City it was given in')
    required(:place).filled(:string).description("Venue ('Oficinas del cliente', 'Zoom')")
    required(:address).filled(:string).description('Address')
    optional(:trainer2).filled(:string).description('Second trainer name')
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
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = save')
  end

  def call(confirm: false, **fields)
    EventWriteService.new(ability: ability, **fields).call(confirm: confirm).to_json
  end
end

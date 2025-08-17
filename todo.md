# Current Tasks

## Assessment Improvements
- subtitle - keventer & report
- update html rules-based report
- pdf report has date in English for a Spanish report

## Rules
- delete test rule button (not implemented)

## Event Type Visibility Cleanup
- review public_event functionality, do we want to keep it?
  - Remove Event model scopes: public_events, public_commercial, public_community_events, public_commercial_visible, public_community_visible, public_and_visible, public_and_past_visible, public_courses
  - Remove visibility_type field from Event model and database
  - Update controllers: home_controller.rb, participants_controller.rb, dashboard_controller.rb, api/event_types_controller.rb
  - Update admin/events.rb - remove visibility_type from forms and displays
  - Remove visibility_type from views: events/_form.html.haml, events/index.html.haml, events/show.html.haml, event_types/events.html.haml
  - Update tests: event_spec.rb, factories.rb, cucumber steps
  - Remove translations for visibility_type from locale files
  - Create migration to remove visibility_type column

## Participants
- best in place editing

## Website17
- Clean up: make layout default

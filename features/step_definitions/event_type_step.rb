# frozen_string_literal: true

def fill_valid_event_type(event_type_name)
  fill_in 'event_type_name', with: event_type_name
  fill_in 'event_type_duration', with: 30
  first(:css, '#event_type_trainer_ids_').click
  fill_in 'event_type_elevator_pitch', with: 'something'
  fill_in 'event_type_description', with: 'something'
  fill_in 'event_type_recipients', with: 'something'
  fill_in 'event_type_program', with: 'something'
end

def create_event_type_with_all_trainers(event_type_name)
  visit '/event_types/new'
  fill_valid_event_type(event_type_name)
  all(:css, '#event_type_trainer_ids_').each { |t| t.set(true) }
  click_button_and_wait 'guardar'
end

When(/^I create a event type with subtitle "(.*?)"$/) do |subtitle|
  visit '/event_types/new'
  fill_valid_event_type 'Evento de Prueba'
  fill_in 'event_type_subtitle', with: subtitle
  click_button_and_wait 'guardar'
end

When(/^I modify the just created event type with subtitle "(.*?)"$/) do |subtitle|
  click_link('last_event_type')
  fill_in 'event_type_subtitle', with: subtitle
  click_button_and_wait 'guardar'
end

# frozen_string_literal: true

def create_valid_event(event_type_name = 'Tipo de Evento de Prueba')
  create_valid_event_inputs event_type_name
end

def create_valid_event_inputs(event_type_name, event_date = '31-01-2030')
  select event_type_name, from: 'event_event_type_id'
  fill_in 'event_date', with: event_date
  fill_in 'event_finish_date', with: Date.parse(event_date) + 1
  fill_in 'event_date', with: event_date
  select 'Presencial', from: 'event_mode'
  fill_in 'event_place', with: 'Hotel Llao Llao'
  fill_in 'event_address', with: 'Tucumán 373'
  fill_in 'event_capacity', with: 25
  fill_in 'event_city', with: 'Buenos Aires'
  select 'Argentina', from: 'event_country_id'
  choose 'event_visibility_type_pu'
  fill_in 'event_list_price', with: 500.00
  check 'event_should_welcome_email'
  check 'event_should_ask_for_referer_code'
  fill_in 'event_eb_price', with: 450.00
  fill_in 'event_specific_conditions', with: 'Algunas condiciones especiales'
end

def submit_event
  click_button_and_wait 'guardar'
end

When(/^I visit the dashboard$/) do
  visit '/dashboard'
end

When(/^I visit the dashboard of "(.*?)"$/) do |country_iso|
  visit "/dashboard/#{country_iso}"
end

Then(/^I should a non empty dashboard event list$/) do
  page.should have_css('ul.unstyled.tasks li')
end

Then(/^I should an empty dashboard event list$/) do
  page.should_not have_css('ul.unstyled.tasks li')
end

Given(/^theres (\d+) event (\d+) week away from now$/) do |amount, weeks_away|
  event_type = EventType.first
  event_date = Date.today + 7 * weeks_away.to_i

  amount.to_i.times do
    create_valid_event_inputs(event_type.name, event_date)
    submit_event
  end
end

When(/^I create an event with extra script "(.*?)"$/) do |extra_script|
  visit '/events/new'
  create_valid_event
  fill_in 'event_extra_script', with: extra_script
  submit_event
end

When(/^go to the last course created$/) do
  click_link('last_event')
end

Then(/^the extra script should be "(.*?)"$/) do |extra_script|
  expect(find_field('event_extra_script').value).to eq(extra_script)
end

When(/^I modify the last event$/) do
  click_link('last_event')
  fill_in 'event_capacity', with: 200
  click_button_and_wait 'guardar'
end

When(/^I create completed event$/) do
  visit '/events/new'
  create_valid_event
  check 'event_is_sold_out'
  submit_event
end

When(/^I create an event with trainers "(.*?)"$/) do |trainers_list|
  create_event_type_with_all_trainers 'Many Trainers'

  trainers = trainers_list.split ','
  fields = %w[event_trainer_id event_trainer2_id event_trainer3_id]
  visit '/events/new'
  create_valid_event 'Many Trainers'

  (0...trainers.count).each do |i|
    select trainers[i], from: fields[i]
  end
  submit_event
end

Then(/^the training (\d+) should be "(.*?)"$/) do |pos, trainer|
  fields = %w[event_trainer_id event_trainer2_id event_trainer3_id]
  expect(find("##{fields[pos.to_i - 1]}")).to have_content trainer
end

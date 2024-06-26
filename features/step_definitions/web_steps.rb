# frozen_string_literal: true

def click_button_and_wait(button)
  click_button button
  page.should_not have_content 'dude, you forgot to assert anything about the view'
end

def click_link_and_wait(link)
  click_link link
  page.should_not have_content 'dude, you forgot to assert anything about the view'
end

Given(/^I visit the home page$/) do
  visit '/'
end

Given(/^I visit the events page$/) do
  visit '/events'
end

Given(/^Im a logged in user$/) do
  visit '/users/sign_in'
  fill_in 'user_email', with: 'ejemplo@eventer.heroku.com'
  fill_in 'user_password', with: 'secret1'
  click_button_and_wait 'Sign in'
end

Then(/^I should see "([^"]*)"$/) do |text|
  page.should have_content(text)
end

When(/^I create a valid event of type "([^"]*)"$/) do |event_name|
  visit '/events/new'
  create_valid_event event_name
  submit_event
end

Given(/^theres an event$/) do
  visit '/events/new'
  create_valid_event
  submit_event
end

When(/^I create an invalid event with "([^"]*)" as "([^"]*)"$/) do |value, attribute|
  visit '/events/new'
  create_valid_event 'Tipo de Evento de Prueba'
  fill_in attribute, with: value
  submit_event
end

When(/^I create a public event on "([^"]*)"$/) do |value|
  visit '/events/new'
  create_valid_event_inputs 'Tipo de Evento de Prueba', value
  fill_in 'event_date', with: value
  fill_in 'event_capacity', with: '10' # solo para sacar el foco del event_date
end

When(/^I create an private event with discounts$/) do
  visit '/events/new'
  create_valid_event 'Tipo de Evento de Prueba'
  choose 'event_visibility_type_pr'
  fill_in 'event_eb_price', with: 10
  fill_in 'event_business_eb_price', with: 15
  submit_event
end

When(/^I create an empty event$/) do
  visit '/events/new'
  submit_event
end

When(/^I visit the event listing page$/) do
  visit '/events'
end

Then(/^I should be on the events listing page$/) do
  current_path.should == events_path
end

Then(/^I should see one event$/) do
  page.should have_content('Curso de Meteorología Básica I')
end

When(/^I choose to create a Private event$/) do
  visit '/events/new'
  create_valid_event_inputs 'Tipo de Evento de Prueba'
  choose 'event_visibility_type_pr'
end

When(/^I choose to create a Community event$/) do
  visit '/events/new'
  create_valid_event_inputs 'Tipo de Evento de Prueba'
  choose 'event_visibility_type_co'
end

When(/^I choose to create a Public event$/) do
  visit '/events/new'
  create_valid_event_inputs 'Tipo de Evento de Prueba'
  choose 'event_visibility_type_pu'
end

Then(/^public prices should be disabled$/) do
  page.find_by_id('event_eb_price')['disabled'].should == 'true'
end

Then(/^I should not see any price$/) do
  page.find('div', id: 'event_public_or_private_set').visible?.should be false
end

Then(/^I should see public prices$/) do
  page.find_field('event_eb_price').visible?.should be true
end

Then(/^EB date should be "([^"]*)"$/) do |value|
  page.should have_field('event_eb_end_date', with: value)
end

When(/^I cancel the event "([^"]*)"$/) do |link_description|
  first(:link, link_description).click

  click_link_and_wait 'Modificar'
  check 'event_cancelled'
  click_button_and_wait 'guardar'
end

Given(/^there is a event type "(.*?)"$/) do |type_name|
  visit '/event_types/new'
  fill_valid_event_type type_name
  click_button_and_wait 'guardar'
end

Then(/^I should not see "([^"]*)"$/) do |text|
  page.should_not have_content(text)
end

When(/^I register for that event$/) do
  visit '/events/1/participants/new'
  fill_in 'participant_fname', with: 'Juan'
  fill_in 'participant_lname', with: 'Callidoro'
  fill_in 'participant_email', with: 'jcallidoro@gmail.com'
  fill_in 'participant_phone', with: '1234-5678'
  #  select 'Argentina - Buenos Aires', :from => 'participant_influence_zone_id'
  all('#participant_influence_zone_id option')[1].select_option
  click_button_and_wait '¡Me interesa!'
end

Then(/^I should see a confirmation message$/) do
  expect(current_path).to eq '/events/1/participant_confirmed'
  expect(page).to have_content('Tu pedido fue realizado exitosamente.')
end

Then(/^It should have a registration page$/) do
  @event = Event.first
  visit "/events/#{@event.id}/participants/new"

  page.should have_content(@event.event_type.name)
  page.should have_content(@event.human_date)
  page.should have_content(@event.city)
end

def create_new_participant
  visit '/events/1/participants/new'
  fill_in 'participant_fname', with: 'Juan'
  fill_in 'participant_lname', with: 'Callidoro'
  fill_in 'participant_email', with: 'jcallidoro@gmail.com'
  fill_in 'participant_phone', with: '1234-5678'
  click_button_and_wait '¡Me interesa!'
end

def contact_participant
  visit '/events/1/participants'
  click_link_and_wait 'modificar'
  select 'Contactado', from: 'participant_status'
  click_button_and_wait 'guardar'
end

Given(/^there are (\d+) participants and 1 is contacted$/) do |newones|
  newones.to_i.times do
    create_new_participant
  end
  contact_participant
end

When(/^I make a blank registration for that event$/) do
  visit '/events/1/participants/new'
  click_button '¡Me interesa!'
end

Given(/^theres an influence zone$/) do
  InfluenceZone.count.should be.positive?
end

Then(/^I should see an alert "([^"]*)"$/) do |msg|
  wait = Selenium::WebDriver::Wait.new(timeout: 10)
  element = wait.until { page.find_by_id('validation_msg') }
  element.text.should == msg
end

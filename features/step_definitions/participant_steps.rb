# encoding: utf-8


Given(/^an event of type "(.*?)" with "(.*?)" as email content$/) do |event_name, content|
  visit '/events/new'
  create_valid_event_inputs event_name
  fill_in 'has_custonm_email', :with => "true"
  fill_in 'custonm_email', :with => content
  submit_event
end

When(/^I register a new participant for the "(.*?)"$/) do |arg1|
  pending # express the regexp above with the code you wish you had
end

Then(/^the Paricipant should recieve an email with "(.*?)"$/) do |arg1|
  pending # express the regexp above with the code you wish you had
end

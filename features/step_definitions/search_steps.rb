# frozen_string_literal: true

When(/^I search for "(.*?)"$/) do |name|
  fill_in 'search_name', with: name
  click_button_and_wait 'search'
end

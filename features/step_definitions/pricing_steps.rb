# frozen_string_literal: true

When(/^I visit Pricing$/) do
  visit '/dashboard/pricing'
end

When(/^I visit pricing of "(.*?)"$/) do |country|
  visit "/dashboard/pricing/#{country}"
end

Then(/^I should see a non empty pricing event list$/) do
  expect(page).to have_css('table tbody tr')
end

Then(/^I should see an empty dashboard event list$/) do
  expect(page).to have_no_css('table tbody tr')
end

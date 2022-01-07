# frozen_string_literal: true

def last_id
  id = 1
  expect(page).to have_css('table tr')
  elem = page.all(:xpath, "//table//tr[td='31 Ene-1 Feb']/td[2]/a").last ||
         page.all(:xpath, "//table//tr[td='31 Jan-1 Feb']/td[2]/a").last
  href = elem[:href] unless elem.nil?
  unless href.nil?
    ri = href.rindex('/')
    id = href[ri + 1, 3]
  end
  id
end

Given(/^there is one event$/) do
  step 'Im a logged in user'
  step 'theres an event'
end

When(/^I visit the "(.*?)" registration page$/) do |lang|
  visit "/events/#{last_id}/participants/new?lang=" + lang
end

When(/^I visit the registration page without languaje$/) do
  visit "/events/#{last_id}/participants/new"
end

Then(/^I can enter a note$/) do
  page.find_field('participant_notes')
end

Given(/^I wait for (\d+) seconds?$/) do |n|
  sleep(n.to_i)
end

Then(/^header should be "(.*?)"$/) do |content|
  expect(find(:css, 'h1').text).to eq(content)
end

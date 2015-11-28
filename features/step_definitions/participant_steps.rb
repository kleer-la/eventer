
def get_last_id
  last_id = 1
  href= page.all(:xpath, "//table//tr[td='31 Ene-1 Feb']/td[2]/a").last[:href]
  if !href.nil?
      ri = href.rindex("/")
      last_id = href[ri+1,3]
  end
  last_id
end


Given(/^there is one event$/) do
    step 'Im a logged in user'
    step 'theres an event'
end

When(/^I visit the "(.*?)" registration page$/) do |lang|
  last_id= get_last_id
  visit "/events/#{last_id}/participants/new?lang="+lang
end

When(/^I visit the registration page without languaje$/) do
  last_id= get_last_id
  visit "/events/#{last_id}/participants/new"
end

Then(/^I can enter a note$/) do
    page.find_field('participant_notes')
end

Given /^I wait for (\d+) seconds?$/ do |n|
  sleep(n.to_i)
end

Then(/^header should be "(.*?)"$/) do |content|
  expect(find(:css, 'h1').text).to  eq(content)
end

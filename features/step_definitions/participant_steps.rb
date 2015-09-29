
@last_id = 1
Given(/^there is one event$/) do
    step 'Im a logged in user'
    step 'theres an event'
    href= page.all(:xpath, "//table//tr[td='31 Ene-1 Feb']/td[2]/a").last[:href]
    puts href
    if !href.nil?
        ri = href.rindex("/")
        @last_id = href[ri+1,3]
        puts @last_id
    end
end

When(/^I visit the "(.*?)" registration page$/) do |lang|
  visit "/events/#{@last_id}/participants/new?lang="+lang

end

When(/^I visit the registration page without languaje$/) do
  visit "/events/#{@last_id}/participants/new"
end

Then(/^I can enter a note$/) do
    page.find_field('participant_notes')
end

Given /^I wait for (\d+) seconds?$/ do |n|
  sleep(n.to_i)
end

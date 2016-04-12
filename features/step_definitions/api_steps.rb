When(/^I request the event list in "(.*?)" format$/) do |ext|
  get "/api/events.#{ext.downcase}"
end

Then(/^it should be an XML$/) do
  expect(last_response.status).to  eq(200)
  expect(last_response.body).to  start_with("<?xml")
end

Then(/^it should have an event$/) do
  parsed= Nokogiri::XML(last_response.body)
  parsed.xpath('//event').should have_at_least(1).items
end

Then(/^it should have extra script in the event$/) do
  parsed= Nokogiri::XML(last_response.body)
  parsed.xpath('//event/extra-script').should have_at_least(1).items
end

Then(/^it should have "(.*?)" in the event type$/) do |xml_element|
  parsed= Nokogiri::XML(last_response.body)
  parsed.xpath('//event/event-type/'+xml_element).should have_at_least(1).items
end

When(/^I request the kleerer list in "(.*?)" format$/) do |ext|
  get "/api/kleerers.#{ext.downcase}"
end

Then(/^it should have "(.*?)"$/) do |element|
  parsed= Nokogiri::XML(last_response.body)
  parsed.xpath(element).should have_at_least(1).items
end

When(/^I request the category list in "(.*?)" format$/) do |ext|
  get "/api/categories.#{ext.downcase}"
end

When(/^I request the v(\d+) event list in "(.*?)" format$/) do |version, format|
  get "/api/#{version}/upcoming_events.#{format.downcase}"
end

Then(/^it should have a JSON event$/) do
  json= JSON.parse(last_response.body)
  expect(json.count).to be > 0
end

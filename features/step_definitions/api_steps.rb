When(/^Im a request the events list in "(.*?)"$/) do |ext|
  get "/api/events.#{ext.downcase}"
end

Then(/^it should be an XML$/) do
#  puts last_response.methods
#  puts last_response.body
  expect(last_response.status).to  eq(200)
  expect(last_response.body).to  start_with("<?xml")
end

Then(/^it should have an event$/) do
  parsed= Nokogiri::XML(last_response.body)
  parsed.xpath('//event').should have_at_least(1).items
end

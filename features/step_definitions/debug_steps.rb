# frozen_string_literal: true

Then(/^show last response body$/) do
  puts '-' * 40
  puts last_response.body
  puts '-' * 40
end

# frozen_string_literal: true

require 'pdf/inspector'

When(/^I visit the certificate page$/) do
  visit '/events/1/participants/1/certificate.pdf'
end

Then(/^I should receive a PDF file$/) do
  pending
  #  page.response_headers['Content-Type'].should == "application/pdf"
  #  pdf = PDF::Inspector::Text.analyze(page.source).strings.join(" ")
  #  page.driver.response.instance_variable_set('@body', pdf)
end

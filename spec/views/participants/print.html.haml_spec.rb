require 'spec_helper'

RSpec.describe "rendering the attendance list template" do
  it "displays the participants" do
  participant= FactoryGirl.create(:participant)
  assign(:participants, [participant])
  assign(:event, participant.event)

  render :template => "participants/print"

  expect(rendered).to match /Juan Carlos/
end
end

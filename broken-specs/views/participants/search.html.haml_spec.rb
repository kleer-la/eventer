require 'spec_helper'

RSpec.describe "rendering the search result template" do
  it "displays the search result" do
    participant= FactoryGirl.create(:participant)
    assign(:participants, [participant])

    render :template => "participants/search"

    expect(rendered).to match /Juan Carlos/
  end
  it "displays a message for nil event type" do
    participant= FactoryGirl.create(:participant)
    participant.event.event_type= nil
    assign(:participants, [participant])

    render :template => "participants/search"

    expect(rendered).to match /sin tipo evento/
  end
end

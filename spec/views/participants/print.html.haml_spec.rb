require 'spec_helper'

RSpec.describe "rendering the attendance list template" do
  it "displays the participant list" do
    participant= FactoryGirl.create(:participant)
    assign(:participants, [participant])
    assign(:event, participant.event)

    render :template => "participants/print"

    expect(rendered).to match /Juan Carlos/
  end
  it "displays a message for an empty participant list" do
    assign(:participants, [])
    assign(:event, FactoryGirl.create(:event))

    render :template => "participants/print"

    expect(rendered).to match /No hay participantes/
  end
end

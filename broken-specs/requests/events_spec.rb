require 'spec_helper'

describe "Events" do
  describe "GET /events" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get events_path
      expect(response.status).to eq 302
    end
  end
end

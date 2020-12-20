require 'spec_helper'

describe "Events" do
  describe "GET /events" do
    include Rack::Test::Methods

    def app
      Rack::Builder.parse_file("config.ru").first
    end
    
    it "event list" do
      event = FactoryGirl.build(:event)      
      event_url= '/api/events.xml'
      get event_url
      expect(last_response.status).to eq 200
    end
  end
end

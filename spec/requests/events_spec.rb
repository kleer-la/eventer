require 'spec_helper'

describe "Events" do
  describe "GET /events" do
    include Rack::Test::Methods

    def app
      Rack::Builder.parse_file("config.ru").first
    end
    
    it "event list in XML" do
      event_url= '/api/events.xml'
      get event_url
      expect(last_response.status).to eq 200
      expect(last_response.body).to start_with("<?xml")
    end

    it "event list public and visible courses in XML" do
      event = FactoryGirl.create(:event)      
      event_url= '/api/events.xml'
      get event_url
      parsed= Nokogiri::XML(last_response.body)
      expect(parsed.xpath('//event').count).to eq 1
    end
  end
end

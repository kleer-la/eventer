require 'spec_helper'

describe "Events" do
  describe "API - GET /events" do
    include Rack::Test::Methods

    def app
      Rack::Builder.parse_file("config.ru").first
    end
    
    context "event list in XML" do
      before(:example) do
        event = FactoryGirl.create(:event)      
        event_url= '/api/events.xml'
        get event_url
        @parsed= Nokogiri::XML(last_response.body)        
      end
    it "XML?" do
      expect(last_response.status).to eq 200
      expect(last_response.body).to start_with("<?xml")
    end

    it "one public and visible course" do
      expect(@parsed.xpath('//event').count).to eq 1
    end

    it "course has a trainer" do
      expect(@parsed.xpath('//event/trainers/trainer').count).to eq 1
    end
    it "course has extra script" do
      expect(@parsed.xpath('//event/extra-script').count).to eq 1
    end
  end
  end
end

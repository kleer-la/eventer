require 'spec_helper'

describe "API Events GET /events" do
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
      expect(@parsed.xpath('//event').count).to be >= 1
    end

    it "course has a trainer" do
      expect(@parsed.xpath('//event/trainers/trainer').count).to be >= 1
    end
    it "course has extra script" do
      expect(@parsed.xpath('//event/extra-script').count).to be >= 1
    end
    it "course event-type has subtitle" do
      expect(@parsed.xpath('//event/event-type/subtitle').count).to be >= 1
    end
  end

  context "event list in JSON" do
    before(:example) do
      event = FactoryGirl.create(:event)      
      event_url= '/api/events.json'
      get event_url
      @json= JSON.parse(last_response.body)
    end
    it "JSON?" do
      expect(@json.count).to be > 0      
    end
  end
end

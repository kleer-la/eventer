require 'rails_helper'

describe "API Categories GET /categories" do
  include Rack::Test::Methods
  def app
    Rack::Builder.parse_file("config.ru").first
  end
  context "category list in XML" do
      before(:example) do
        event = FactoryBot.create(:category, visible: true)      
        event_url= '/api/categories.xml'
        get event_url
        @parsed= Nokogiri::XML(last_response.body)        
      end
    it "XML?" do
      expect(last_response.status).to eq 200
      expect(last_response.body).to start_with("<?xml")
    end

    it "one visible category" do
      expect(@parsed.xpath('/categories/category').count).to eq 1
    end
end
end
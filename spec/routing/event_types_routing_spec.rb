require 'rails_helper'

describe EventTypesController do
  describe "routing" do

    it "routes to #index" do
      expect(get("/event_types")).to route_to("event_types#index")
    end

    it "routes to #new" do
      expect(get("/event_types/new")).to route_to("event_types#new")
    end

    it "routes to #show" do
      expect(get("/event_types/1")).to route_to("event_types#show", :id => "1")
    end

    it "routes to #edit" do
      expect(get("/event_types/1/edit")).to route_to("event_types#edit", :id => "1")
    end

    it "routes to #create" do
      expect(post("/event_types")).to route_to("event_types#create")
    end

    it "routes to #update" do
      expect(put("/event_types/1")).to route_to("event_types#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(delete("/event_types/1")).to route_to("event_types#destroy", :id => "1")
    end

  end
end

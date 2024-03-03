require "rails_helper"

RSpec.describe ServiceAreasController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/service_areas").to route_to("service_areas#index")
    end

    it "routes to #new" do
      expect(get: "/service_areas/new").to route_to("service_areas#new")
    end

    it "routes to #show" do
      expect(get: "/service_areas/1").to route_to("service_areas#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/service_areas/1/edit").to route_to("service_areas#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/service_areas").to route_to("service_areas#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/service_areas/1").to route_to("service_areas#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/service_areas/1").to route_to("service_areas#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/service_areas/1").to route_to("service_areas#destroy", id: "1")
    end
  end
end

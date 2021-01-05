require 'rails_helper'

describe HomeController do

  describe "GET 'index' (/api/events.<format>)" do
    it "returns http success" do
      get 'index'
      expect(response).to be_success
    end
    it "returns events" do
      event = FactoryBot.create(:event)
      get 'index'
      expect(assigns(:events)).to eq [event]
    end
    it "returns non draft events" do
      event = FactoryBot.create(:event, place: "here")
      draft = FactoryBot.create(:event, place: "there", draft: true)
      get 'index'
      expect(assigns(:events).map(&:place)).to eq ["here"]
    end
  end

end

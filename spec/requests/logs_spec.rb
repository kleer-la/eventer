require 'rails_helper'

RSpec.describe "Logs", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/logs"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      Log.log(:xero, :info, 'Hello darkness my old friend')
      get "/logs/1"
      expect(response).to have_http_status(:success)
    end
  end

end

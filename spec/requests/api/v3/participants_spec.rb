require 'rails_helper'

RSpec.describe "Api::V3::Participants", type: :request do
  describe "POST /interest" do
    before(:example) do
      @event = FactoryBot.create(:event)
      iz= FactoryBot.create(:influence_zone, country: Country.find_by(iso_code: 'AR'))
    end
    it "returns http success" do
      post "/api/v3/participants/interest"
      expect(response).to have_http_status(:success)
    end
    it "add to an event" do
      request_body = {
        event_id: @event.id,
        event_type_id: 0,
        firstname: 'New',
        lastname: 'Participant',
        country_iso: 'AR', 
        email: 'new@gmail.com',
        notes: 'New comment'
      }
      expect {
        post("/api/v3/participants/interest", params: request_body)
      }.to change(Participant, :count).by(1)

      expect(response).to have_http_status(:success)
    end

    it "fail to add to an event (missing attributes)" do
      request_body = {
        event_id: @event.id,
        event_type_id: 0,
        firstname: '',
        lastname: '',
        country_iso: 'AR', 
        email: '',
        notes: 'New comment'
      }
      expect {
        post("/api/v3/participants/interest", params: request_body)
      }.to change(Participant, :count).by(0)

      expect(response).to have_http_status(:bad_request)
      expect(response.body).to match /Fname/
      expect(response.body).to match /Lname/
      expect(response.body).to match /Email/
    end
  end

end

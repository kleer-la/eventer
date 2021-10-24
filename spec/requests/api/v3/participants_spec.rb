require 'rails_helper'

RSpec.describe "Api::V3::Participants", type: :request do
  describe "PUT /interest" do
    before(:example) do
      @event = FactoryBot.create(:event)
      FactoryBot.create(:influence_zone)
    end
    it "returns http success" do
      put "/api/v3/participants/interest"
      expect(response).to have_http_status(:success)
    end
    it "add to an event" do
      request_body = {
        event_id: @event.id,
        event_type_id: 0,
        firstname: 'New',
        lastname: 'Participant',
        country_iso: 'UY', 
        email: 'new@gmail.com',
        notes: 'New comment'
      }
      expect {
        put("/api/v3/participants/interest", params: request_body)
      }.to change(Participant, :count).by(1)

      expect(response).to have_http_status(:success)
    end

    it "fail to add to an event (missing attributes)" do
      request_body = {
        event_id: @event.id,
        event_type_id: 0,
        firstname: '',
        lastname: '',
        country_iso: 'UY', 
        email: '',
        notes: 'New comment'
      }
      expect {
        put("/api/v3/participants/interest", params: request_body)
      }.to change(Participant, :count).by(0)

      expect(response).to have_http_status(:bad_request)
      expect(response.body).to match /Fname/
      expect(response.body).to match /Lname/
      expect(response.body).to match /Email/
    end
  end

end

require 'spec_helper'


# describe ApiController do

#   describe "GET 'index'" do
#     before(:each) do
#       @request.env["devise.mapping"] = Devise.mappings[:user]
#       @user = FactoryGirl.create(:administrator)
#       sign_in @user
#     end

#     # This should return the minimal set of values that should be in the session
#     # in order to pass any filters (e.g. authentication) defined in
#     # ApiController. Be sure to keep this updated too.
#     def valid_session
#       nil
#     end

#     it "returns http success" do
#       get 'index', :format => 'json'
#       expect(response).to be_success
#     end

#     it "returns proper fields" do
#       FactoryGirl.create(:event)
#       get 'index', :format => 'json'
#       json= JSON.parse(response.body)
#       expect(json.count).to be > 0
#       expect(json[0]).to include("id","name", "country_name", "country_iso", "date", "finish_date", "city")
#     end
#   end
# end

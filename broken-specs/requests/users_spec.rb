require 'spec_helper'

# describe "Users" do
#   describe "GET /users" do
    
#     it "should allow identified users" do
#       @user = FactoryGirl.create(:administrator)
#       post_via_redirect user_session_path, 'user[email]' => @user.email, 'user[password]' => "please"
      
#       get users_path
      
#       response.status.should be(200)
#     end
    
#     it "should not allow guest users" do
#       get users_path
      
#       response.status.should be(302)
#     end
    
#   end
# end

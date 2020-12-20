require 'spec_helper'

# describe "Roles" do
#   describe "GET /roles" do
    
#     it "should allow identified administrators" do
#       @user = FactoryGirl.create(:administrator)
#       post_via_redirect user_session_path, 'user[email]' => @user.email, 'user[password]' => "please"
      
#       get roles_path
      
#       response.status.should be(200)
#     end
    
#     it "should not allow guest users" do
#       get roles_path
      
#       response.status.should be(302)
#     end
    
#   end
# end

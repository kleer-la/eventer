require 'rails_helper'



# describe UsersController do

#     context "If user is not administrator" do

#       before(:each) do
#         @request.env["devise.mapping"] = Devise.mappings[:user]
#         @user = FactoryBot.create(:user)
#         sign_in @user
#       end

#       describe "GET index" do
#         it "should raise CanCan::AccessDenied" do
#           expect{ get :index }.to raise_error CanCan::AccessDenied
#         end
#       end

#       #describe "GET show" do
#       #  it "should raise CanCan::AccessDenied" do
#       #    expect{ get :show }.to raise_error CanCan::AccessDenied
#       #  end
#       #end

#       describe "GET new" do
#         it "should raise CanCan::AccessDenied" do
#           expect{ get :new }.to raise_error CanCan::AccessDenied

#         end
#       end

#       #describe "GET edit" do
#       #  it "should raise CanCan::AccessDenied" do
#       #    expect{ get :edit }.to raise_error CanCan::AccessDenied
#       #  end
#       #end

#     end

# end

require 'spec_helper'



# describe RolesController do
  

#   # This should return the minimal set of attributes required to create a valid
#   # Role. As you add validations to Role, be sure to
#   # update the return value of this method accordingly.
#   def valid_attributes
#     { :name => "a-role-name" }
#   end
  
#   # This should return the minimal set of values that should be in the session
#   # in order to pass any filters (e.g. authentication) defined in
#   # RolesController. Be sure to keep this updated too.
#   def valid_session
#     nil
#   end
  
#   context "If user is administrator" do
    
#     before(:each) do
#       @request.env["devise.mapping"] = Devise.mappings[:user]
#       @user = FactoryGirl.create(:administrator)
#       sign_in @user
#     end

#     describe "GET index" do
#       it "assigns all roles as @roles" do
#         role = Role.create! valid_attributes
#         roles_all = Role.all
#         get :index, {}, valid_session
#         assigns(:roles).should eq(roles_all)
#       end
#     end

#     describe "GET show" do
#       it "assigns the requested role as @role" do
#         role = Role.create! valid_attributes
#         get :show, {:id => role.to_param}, valid_session
#         assigns(:role).should eq(role)
#       end
#     end

#     describe "GET new" do
#       it "assigns a new role as @role" do
#         get :new, {}, valid_session
#         assigns(:role).should be_a_new(Role)
#       end
#     end

#     describe "GET edit" do
#       it "assigns the requested role as @role" do
#         role = Role.create! valid_attributes
#         get :edit, {:id => role.to_param}, valid_session
#         assigns(:role).should eq(role)
#       end
#     end

#     describe "POST create" do
#       describe "with valid params" do
#         it "creates a new Role" do
#           expect {
#             post :create, {:role => valid_attributes}, valid_session
#           }.to change(Role, :count).by(1)
#         end

#         it "assigns a newly created role as @role" do
#           post :create, {:role => valid_attributes}, valid_session
#           assigns(:role).should be_a(Role)
#           assigns(:role).should be_persisted
#         end

#         it "redirects to the created role" do
#           post :create, {:role => valid_attributes}, valid_session
#           response.should redirect_to(Role.last)
#         end
#       end

#       describe "with invalid params" do
#         it "assigns a newly created but unsaved role as @role" do
#           # Trigger the behavior that occurs when invalid params are submitted
#           Role.any_instance.stub(:save).and_return(false)
#           post :create, {:role => {}}, valid_session
#           assigns(:role).should be_a_new(Role)
#         end

#         it "re-renders the 'new' template" do
#           # Trigger the behavior that occurs when invalid params are submitted
#           Role.any_instance.stub(:save).and_return(false)
#           post :create, {:role => {}}, valid_session
#           response.should render_template("new")
#         end
#       end
#     end

#     describe "PUT update" do
#       describe "with valid params" do
#         it "updates the requested role" do
#           role = Role.create! valid_attributes
#           # Assuming there are no other roles in the database, this
#           # specifies that the Role created on the previous line
#           # receives the :update_attributes message with whatever params are
#           # submitted in the request.
#           Role.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
#           put :update, {:id => role.to_param, :role => {'these' => 'params'}}, valid_session
#         end

#         it "assigns the requested role as @role" do
#           role = Role.create! valid_attributes
#           put :update, {:id => role.to_param, :role => valid_attributes}, valid_session
#           assigns(:role).should eq(role)
#         end

#         it "redirects to the role" do
#           role = Role.create! valid_attributes
#           put :update, {:id => role.to_param, :role => valid_attributes}, valid_session
#           response.should redirect_to(role)
#         end
#       end

#       describe "with invalid params" do
#         it "assigns the role as @role" do
#           role = Role.create! valid_attributes
#           # Trigger the behavior that occurs when invalid params are submitted
#           Role.any_instance.stub(:save).and_return(false)
#           put :update, {:id => role.to_param, :role => {}}, valid_session
#           assigns(:role).should eq(role)
#         end

#         it "re-renders the 'edit' template" do
#           role = Role.create! valid_attributes
#           # Trigger the behavior that occurs when invalid params are submitted
#           Role.any_instance.stub(:save).and_return(false)
#           put :update, {:id => role.to_param, :role => {}}, valid_session
#           response.should render_template("edit")
#         end
#       end
#     end

#     describe "DELETE destroy" do
#       it "destroys the requested role" do
#         role = Role.create! valid_attributes
#         expect {
#           delete :destroy, {:id => role.to_param}, valid_session
#         }.to change(Role, :count).by(-1)
#       end

#       it "redirects to the roles list" do
#         role = Role.create! valid_attributes
#         delete :destroy, {:id => role.to_param}, valid_session
#         response.should redirect_to(roles_url)
#       end
#     end
#   end
  
#   context "If user is not administrator" do
    
#     before(:each) do
#       @request.env["devise.mapping"] = Devise.mappings[:user]
#       @user = FactoryGirl.create(:user)
#       sign_in @user
#     end

#     describe "GET index" do
#       it "should raise CanCan::AccessDenied" do
#         expect{ get :index }.to raise_error CanCan::AccessDenied
#       end
#     end

#     #describe "GET show" do
#     #  it "should raise CanCan::AccessDenied" do
#     #    expect{ get :show }.to raise_error CanCan::AccessDenied
#     #  end
#     #end

#     describe "GET new" do
#       it "should raise CanCan::AccessDenied" do
#         expect{ get :new }.to raise_error CanCan::AccessDenied
        
#       end
#     end

#     #describe "GET edit" do
#     #  it "should raise CanCan::AccessDenied" do
#     #    expect{ get :edit }.to raise_error CanCan::AccessDenied
#     #  end
#     #end

#   end

# end

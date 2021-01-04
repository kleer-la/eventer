require 'rails_helper'
require_relative "../support/devise"

describe RolesController do 
  
  context "If user is administrator" do
    login_admin

    before(:each) do
      @role= FactoryBot.create(:comercial_role)
    end
    describe "GET index" do
      it "assigns all roles as @roles" do
        get :index, {}
        expect(assigns(:roles).map(&:name)).to match_array ["administrator","comercial"]
      end
    end

    describe "GET show" do
      it "assigns the requested role as @role" do
        get :show, {:id => @role.to_param}
        expect(assigns(:role)).to eq @role
      end
    end

    describe "GET new" do
      it "assigns a new role as @role" do
        get :new, {}
        expect(assigns(:role)).to be_a_new Role
      end
    end

    describe "GET edit" do
      it "assigns the requested role as @role" do
        get :edit, {:id => @role.to_param}
        expect(assigns(:role)).to eq @role
      end
    end

    describe "POST create" do
      describe "with valid params" do
        it "creates a new Role" do
          expect {
            post :create, {:role => @role.attributes}
          }.to change(Role, :count).by(1)
        end

        it "assigns a newly created role as @role" do
          post :create, {:role => @role.attributes}
          expect(assigns(:role)).to be_a Role
          expect(assigns(:role)).to be_persisted
        end

        it "redirects to the created role" do
          post :create, {:role => @role.attributes}
          expect(response).to redirect_to(Role.last)
        end
      end

      describe "with invalid params" do
        before(:each) do 
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Role).to receive(:save).and_return(false)
          post :create, {:role => {}}
        end
        it "assigns a newly created but unsaved role as @role" do
          expect(assigns(:role)).to be_a_new Role
        end

        it "re-renders the 'new' template" do
          expect(response).to render_template("new")
        end
      end
    end

    describe "PUT update" do
      describe "with valid params" do
        it "updates the requested role" do
          # Assuming there are no other roles in the database, this
          # specifies that the Role created on the previous line
          # receives the :update_attributes message with whatever params are
          # submitted in the request.
          expect_any_instance_of(Role).to receive(:update_attributes).with({'these' => 'params'})
          put :update, {:id => @role.to_param, :role => {'these' => 'params'}}
        end

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
      end

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
    end

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
#       @user = FactoryBot.create(:user)
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

  end

end

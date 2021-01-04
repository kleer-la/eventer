require 'rails_helper'


# describe TrainersController do

#   # This should return the minimal set of attributes required to create a valid
#   # Trainer. As you add validations to Trainer, be sure to
#   # update the return value of this method accordingly.
#   def valid_attributes
#     {
#       :name => "Anibal Smith",
#       :bio => "prprororrprororp" 
#     }
#   end
  
#   # This should return the minimal set of values that should be in the session
#   # in order to pass any filters (e.g. authentication) defined in
#   # TrainersController. Be sure to keep this updated too.
#   def valid_session
#     nil
#   end
  
#   before(:each) do
#     @request.env["devise.mapping"] = Devise.mappings[:user]
#     @user = FactoryBot.create(:administrator)
#     sign_in @user
#   end

#   describe "GET index" do
#     it "assigns all trainers as @trainers" do
#       trainer = Trainer.create! valid_attributes
#       get :index, {}, valid_session
#       assigns(:trainers).should eq([trainer])
#     end
#   end

#   describe "GET show" do
#     it "assigns the requested trainer as @trainer" do
#       trainer = Trainer.create! valid_attributes
#       get :show, {:id => trainer.to_param}, valid_session
#       assigns(:trainer).should eq(trainer)
#     end
#   end

#   describe "GET new" do
#     it "assigns a new trainer as @trainer" do
#       get :new, {}, valid_session
#       assigns(:trainer).should be_a_new(Trainer)
#     end
#   end

#   describe "GET edit" do
#     it "assigns the requested trainer as @trainer" do
#       trainer = Trainer.create! valid_attributes
#       get :edit, {:id => trainer.to_param}, valid_session
#       assigns(:trainer).should eq(trainer)
#     end
#   end

#   describe "POST create" do
#     describe "with valid params" do
#       it "creates a new Trainer" do
#         expect {
#           post :create, {:trainer => valid_attributes}, valid_session
#         }.to change(Trainer, :count).by(1)
#       end

#       it "assigns a newly created trainer as @trainer" do
#         post :create, {:trainer => valid_attributes}, valid_session
#         assigns(:trainer).should be_a(Trainer)
#         assigns(:trainer).should be_persisted
#       end

#       it "redirects to the created trainer" do
#         post :create, {:trainer => valid_attributes}, valid_session
#         response.should redirect_to(trainers_path)
#       end
#     end

#     describe "with invalid params" do
#       it "assigns a newly created but unsaved trainer as @trainer" do
#         # Trigger the behavior that occurs when invalid params are submitted
#         Trainer.any_instance.stub(:save).and_return(false)
#         post :create, {:trainer => {}}, valid_session
#         assigns(:trainer).should be_a_new(Trainer)
#       end

#       it "re-renders the 'new' template" do
#         # Trigger the behavior that occurs when invalid params are submitted
#         Trainer.any_instance.stub(:save).and_return(false)
#         post :create, {:trainer => {}}, valid_session
#         response.should render_template("new")
#       end
#     end
#   end

#   describe "PUT update" do
#     describe "with valid params" do
#       it "updates the requested trainer" do
#         trainer = Trainer.create! valid_attributes
#         # Assuming there are no other trainers in the database, this
#         # specifies that the Trainer created on the previous line
#         # receives the :update_attributes message with whatever params are
#         # submitted in the request.
#         Trainer.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
#         put :update, {:id => trainer.to_param, :trainer => {'these' => 'params'}}, valid_session
#       end

#       it "assigns the requested trainer as @trainer" do
#         trainer = Trainer.create! valid_attributes
#         put :update, {:id => trainer.to_param, :trainer => valid_attributes}, valid_session
#         assigns(:trainer).should eq(trainer)
#       end

#       it "redirects to the trainer" do
#         trainer = Trainer.create! valid_attributes
#         put :update, {:id => trainer.to_param, :trainer => valid_attributes}, valid_session
#         response.should redirect_to(trainers_path)
#       end
#     end

#     describe "with invalid params" do
#       it "assigns the trainer as @trainer" do
#         trainer = Trainer.create! valid_attributes
#         # Trigger the behavior that occurs when invalid params are submitted
#         Trainer.any_instance.stub(:save).and_return(false)
#         put :update, {:id => trainer.to_param, :trainer => {}}, valid_session
#         assigns(:trainer).should eq(trainer)
#       end

#       it "re-renders the 'edit' template" do
#         trainer = Trainer.create! valid_attributes
#         # Trigger the behavior that occurs when invalid params are submitted
#         Trainer.any_instance.stub(:save).and_return(false)
#         put :update, {:id => trainer.to_param, :trainer => {}}, valid_session
#         response.should render_template("edit")
#       end
#     end
#   end

#   describe "DELETE destroy" do
#     it "destroys the requested trainer" do
#       trainer = Trainer.create! valid_attributes
#       expect {
#         delete :destroy, {:id => trainer.to_param}, valid_session
#       }.to change(Trainer, :count).by(-1)
#     end

#     it "redirects to the trainers list" do
#       trainer = Trainer.create! valid_attributes
#       delete :destroy, {:id => trainer.to_param}, valid_session
#       response.should redirect_to(trainers_url)
#     end
#   end

# end

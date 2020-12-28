# encoding: utf-8

require 'spec_helper'


# describe EventTypesController do

#   # This should return the minimal set of attributes required to create a valid
#   # EventType. As you add validations to EventType, be sure to
#   # update the return value of this method accordingly.
#   def valid_attributes
#      { :name => "Pepe",
#        :duration => 8,
#        :elevator_pitch => "un speech grooooso",
#        :goal => "Un objetivo",
#        :description => "Una descripción",
#        :recipients => "algunos destinatarios",
#        :program => "El programa del evento",
#        :trainer_ids => [ FactoryBot.create(:trainer).id ]
#        }
#    end
  
#   # This should return the minimal set of values that should be in the session
#   # in order to pass any filters (e.g. authentication) defined in
#   # EventTypesController. Be sure to keep this updated too.
#   def valid_session
#     nil
#   end
  
#   before(:each) do
#     @request.env["devise.mapping"] = Devise.mappings[:user]
#     @user = FactoryBot.create(:administrator)
#     sign_in @user
#   end

#   describe "GET index" do
#     it "assigns all event_types as @event_types" do
#       event_type = EventType.create! valid_attributes
#       get :index, {}, valid_session
#       assigns(:event_types).should eq([event_type])
#     end
#   end

#   describe "GET show" do
#     it "assigns the requested event_type as @event_type" do
#       event_type = EventType.create! valid_attributes
#       get :show, {:id => event_type.to_param}, valid_session
#       assigns(:event_type).should eq(event_type)
#     end
#   end

#   describe "GET new" do
#     it "assigns a new event_type as @event_type" do
#       get :new, {}, valid_session
#       assigns(:event_type).should be_a_new(EventType)
#     end
#   end

#   describe "GET edit" do
#     it "assigns the requested event_type as @event_type" do
#       event_type = EventType.create! valid_attributes
#       get :edit, {:id => event_type.to_param}, valid_session
#       assigns(:event_type).should eq(event_type)
#     end
#   end

#   describe "POST create" do
#     describe "with valid params" do
#       it "creates a new EventType" do
#         expect {
#           post :create, {:event_type => valid_attributes}, valid_session
#         }.to change(EventType, :count).by(1)
#       end

#       it "assigns a newly created event_type as @event_type" do
#         post :create, {:event_type => valid_attributes}, valid_session
#         assigns(:event_type).should be_a(EventType)
#         assigns(:event_type).should be_persisted
#       end

#       it "redirects to the created event_type" do
#         post :create, {:event_type => valid_attributes}, valid_session
#         response.should redirect_to(EventType)
#       end
#     end

#     describe "with invalid params" do
#       it "assigns a newly created but unsaved event_type as @event_type" do
#         # Trigger the behavior that occurs when invalid params are submitted
#         EventType.any_instance.stub(:save).and_return(false)
#         post :create, {:event_type => {}}, valid_session
#         assigns(:event_type).should be_a_new(EventType)
#       end

#       it "re-renders the 'new' template" do
#         # Trigger the behavior that occurs when invalid params are submitted
#         EventType.any_instance.stub(:save).and_return(false)
#         post :create, {:event_type => {}}, valid_session
#         response.should render_template("new")
#       end
#     end
#   end

#   describe "PUT update" do
#     describe "with valid params" do
#       it "updates the requested event_type" do
#         event_type = EventType.create! valid_attributes
#         # Assuming there are no other event_types in the database, this
#         # specifies that the EventType created on the previous line
#         # receives the :update_attributes message with whatever params are
#         # submitted in the request.
#         EventType.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
#         put :update, {:id => event_type.to_param, :event_type => {'these' => 'params'}}, valid_session
#       end

#       it "assigns the requested event_type as @event_type" do
#         event_type = EventType.create! valid_attributes
#         put :update, {:id => event_type.to_param, :event_type => valid_attributes}, valid_session
#         assigns(:event_type).should eq(event_type)
#       end

#       it "redirects to the event_type" do
#         event_type = EventType.create! valid_attributes
#         put :update, {:id => event_type.to_param, :event_type => valid_attributes}, valid_session
#         response.should redirect_to(EventType)
#       end
#     end

#     describe "with invalid params" do
#       it "assigns the event_type as @event_type" do
#         event_type = EventType.create! valid_attributes
#         # Trigger the behavior that occurs when invalid params are submitted
#         EventType.any_instance.stub(:save).and_return(false)
#         put :update, {:id => event_type.to_param, :event_type => {}}, valid_session
#         assigns(:event_type).should eq(event_type)
#       end

#       it "re-renders the 'edit' template" do
#         event_type = EventType.create! valid_attributes
#         # Trigger the behavior that occurs when invalid params are submitted
#         EventType.any_instance.stub(:save).and_return(false)
#         put :update, {:id => event_type.to_param, :event_type => {}}, valid_session
#         response.should render_template("edit")
#       end
#     end
#   end

#   describe "DELETE destroy" do
#     it "destroys the requested event_type" do
#       event_type = EventType.create! valid_attributes
#       expect {
#         delete :destroy, {:id => event_type.to_param}, valid_session
#       }.to change(EventType, :count).by(-1)
#     end

#     it "redirects to the event_types list" do
#       event_type = EventType.create! valid_attributes
#       delete :destroy, {:id => event_type.to_param}, valid_session
#       response.should redirect_to(event_types_url)
#     end
#   end

# end

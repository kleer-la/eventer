require 'rails_helper'
require_relative "../support/devise"

describe EventTypesController do
  login_admin

#   # This should return the minimal set of values that should be in the session
#   # in order to pass any filters (e.g. authentication) defined in
#   # EventTypesController. Be sure to keep this updated too.
  def valid_session
    nil
  end
  
  describe "GET index" do
    it "assigns all event_types as @event_types" do
      event_type = FactoryBot.create(:event_type)
      get :index, {}, valid_session
      expect(assigns(:event_types)).to eq [event_type]
    end
  end
  
  describe "GET show" do
    it "assigns the requested event_type as @event_type" do
      event_type = FactoryBot.create(:event_type)
      get :show, {:id => event_type.to_param}, valid_session
      expect(assigns(:event_type)).to eq event_type
    end
  end
  
  describe "GET new" do
    it "assigns a new event_type as @event_type" do
      get :new, {}, valid_session
      expect(assigns(:event_type)).to be_a_new(EventType)
    end
  end
  
  describe "GET edit" do
    it "assigns the requested event_type as @event_type" do
      event_type = FactoryBot.create(:event_type)
      get :edit, {:id => event_type.to_param}, valid_session
      expect(assigns(:event_type)).to eq event_type
    end
  end

  describe "POST create" do
    before(:each) do
      trainer= FactoryBot.create(:trainer)
      event_type= FactoryBot.build(:event_type)
      @event_type_att= event_type.attributes.reject {|k,v| %w(id created_at updated_at average_rating net_promoter_score surveyed_count promoter_count).include? k}
      @event_type_att[:trainer_ids] = [trainer.id.to_s]
    end
    describe "with valid params" do
      it "creates a new EventType" do
        expect {
          post :create, {:event_type => @event_type_att}, valid_session
        }.to change(EventType, :count).by(1)
      end

      it "assigns a newly created event_type as @event_type" do
        post :create, {:event_type => @event_type_att}, valid_session
        expect(assigns(:event_type)).to be_a EventType
        expect(assigns(:event_type)).to be_persisted
      end
      
      it "redirects to the created event_type" do
        post :create, {:event_type => @event_type_att}, valid_session
        expect(response).to redirect_to EventType
      end
    end

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
  end

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

end

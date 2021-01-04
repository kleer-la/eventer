require 'rails_helper'
require_relative "../support/devise"

describe EventTypesController do
  login_admin
  
  describe "GET index" do
    it "assigns all event_types as @event_types" do
      event_type = FactoryBot.create(:event_type)
      get :index, {}
      expect(assigns(:event_types)).to eq [event_type]
    end
  end
  
  describe "GET show" do
    it "assigns the requested event_type as @event_type" do
      event_type = FactoryBot.create(:event_type)
      get :show, {:id => event_type.to_param}
      expect(assigns(:event_type)).to eq event_type
    end
  end
  
  describe "GET new" do
    it "assigns a new event_type as @event_type" do
      get :new, {}
      expect(assigns(:event_type)).to be_a_new(EventType)
    end
  end
  
  describe "GET edit" do
    it "assigns the requested event_type as @event_type" do
      event_type = FactoryBot.create(:event_type)
      get :edit, {:id => event_type.to_param}
      expect(assigns(:event_type)).to eq event_type
    end
  end

  describe "POST create" do
    before(:each) do
      trainer= FactoryBot.create(:trainer)
      event_type= FactoryBot.build(:event_type)
      @event_type_att= event_type.attributes.reject {|k,v| 
        %w(id created_at updated_at average_rating net_promoter_score surveyed_count promoter_count).include? k}
      @event_type_att[:trainer_ids] = [trainer.id.to_s]
    end
    describe "with valid params" do
      it "creates a new EventType" do
        expect {
          post :create, {:event_type => @event_type_att}
        }.to change(EventType, :count).by(1)
      end

      it "assigns a newly created event_type as @event_type" do
        post :create, {:event_type => @event_type_att}
        expect(assigns(:event_type)).to be_a EventType
        expect(assigns(:event_type)).to be_persisted
      end
      
      it "redirects to the created event_type" do
        post :create, {:event_type => @event_type_att}
        expect(response).to redirect_to EventType
      end
    end

    describe "with invalid params" do
      before(:each) do 
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(EventType).to receive(:save).and_return(false)
        post :create, {:event_type => {}}          
      end
      it "assigns a newly created but unsaved event_type as @event_type" do
        expect(assigns(:event_type)).to be_a_new(EventType)
      end

      it "re-renders the 'new' template" do
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      before(:each) do 
        @event_type = FactoryBot.create :event_type
      end
      it "updates the requested event_type" do
          expect_any_instance_of(EventType).to receive(:update_attributes).with({'these' => 'params'})
          put :update, {:id => @event_type.to_param, :event_type => {'these' => 'params'}}
      end

      it "assigns the requested event_type as @event_type" do
        put :update, {:id => @event_type.to_param, :event_type => {}}
        expect(assigns(:event_type)).to eq @event_type
        expect(response).to redirect_to(event_types_path)
        expect(flash[:notice]).to include "modificado"
      end
    end

    describe "with invalid params" do
      before(:each) do 
        @event_types = FactoryBot.create :event_type
        allow_any_instance_of(EventType).to receive(:save).and_return(false)
        put :update, {:id => @event_types.to_param, :event => {}}
      end
      it "assigns the event_type as @event_type" do
        expect(assigns(:event)).to eq @event_type
      end

      it "re-renders the 'edit' template" do
        expect(response).to render_template(:edit)
      end
    end
  end

  describe "DELETE destroy" do
    before(:each) do 
      @event_type = FactoryBot.create :event_type
    end
    it "destroys the requested event_type" do
      expect {
        delete :destroy, {:id => @event_type.to_param}
      }.to change(EventType, :count).by(-1)
    end

    it "redirects to the event_types list" do
      delete :destroy, {:id => @event_type.to_param}
      expect(response).to redirect_to(event_types_url)
    end
  end

end

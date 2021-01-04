require 'rails_helper'
require_relative "../support/devise"

describe EventsController do

  context "the user is a admin" do
    login_admin

    describe "GET new" do
      it "assigns a new event as @event" do
        get :new, {}
        expect(assigns(:event)).to be_a_new(Event)
      end
    end
  end
  
  context "the user is a comercial" do
    login_comercial
  
    describe "GET index" do
      it "assigns all events as @events" do
        event = FactoryBot.create(:event)
        get :index, {}
        expect(assigns(:events)).to eq [event]
      end
    end

    describe "GET show" do
      it "assigns the requested event as @event" do
        event = FactoryBot.create(:event)
        get :show, {:id => event.to_param}
        expect(assigns(:event)).to eq event
      end
    end

    describe "GET new" do
      it "assigns a new event as @event" do
        get :new, {}
        expect(assigns(:event)).to be_a_new(Event)
      end
    end

    describe "GET edit" do
      it "assigns the requested event as @event" do
        event = FactoryBot.create(:event)
        get :edit, {:id => event.to_param}
        expect(assigns(:event)).to eq event
      end
    end

    describe "POST create" do
      describe "with valid params" do
        before(:each) do
          event_type= FactoryBot.create(:event_type)
          country= FactoryBot.create(:country)
          trainer= FactoryBot.create(:trainer)
          event= FactoryBot.build(:event, 
            event_type: event_type,
            country: country,
            trainer: trainer
          )
          @event_attr= event.attributes.reject {|k,v| 
            %w(id created_at updated_at average_rating net_promoter_score).include? k}
          @event_attr["event_type_id"] = event_type.id.to_s
          @event_attr["country_id"] = country.id.to_s
          @event_attr["trainer_id"] = trainer.id.to_s
        end
        it "creates a new Event" do
          expect {
            post :create, :event => @event_attr
          }.to change(Event, :count).by(1)
        end

        it "assigns a newly created event as @event" do
          post :create, {:event => @event_attr}
          expect(assigns(:event)).to be_a Event
          expect(assigns(:event)).to be_persisted
        end

        it "redirects to the created event" do
          post :create, {:event => @event_attr}
          expect(response).to redirect_to(events_path)
        end
      end

      describe "with invalid params" do
        before(:each) do 
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Event).to receive(:save).and_return(false)
          post :create, {:event => {}}          
        end
        it "assigns a newly created but unsaved event as @event" do
          expect(assigns(:event)).to be_a_new(Event)
        end
        
        it "re-renders the 'new' template" do
          expect(assigns(:event)).to render_template("new")
        end
      end
    end

    describe "PUT update" do
      describe "with valid params" do
        before(:each) do 
          @event = FactoryBot.create :event
        end
        it "updates the requested event" do
          expect_any_instance_of(Event).to receive(:update_attributes).with({'these' => 'params'})
          put :update, {:id => @event.to_param, :event => {'these' => 'params'}}
        end
        
        it "ok w/o change" do
          put :update, {:id => @event.to_param, :event => {}}
          expect(assigns(:event)).to eq @event
          expect(response).to redirect_to(events_path)
          expect(flash[:notice]).to include "modificado"
        end
        it "@event cancelled" do
          put :update, {:id => @event.to_param, :event => {:cancelled => true}}
          expect(response).to redirect_to(events_path)
          expect(flash[:notice]).to include "cancelado"
        end
      end
      
      describe "with invalid params" do
        before(:each) do 
          @event = FactoryBot.create :event
          allow_any_instance_of(Event).to receive(:save).and_return(false)
          put :update, {:id => @event.to_param, :evemt => {}}
        end
        it "assigns the event as @event" do
          expect(assigns(:event)).to eq @event
        end
        
        it "re-renders the 'edit' template" do
          expect(response).to render_template(:edit)
        end
      end
    end

    describe "DELETE destroy" do
      before(:each) do 
        @event = FactoryBot.create :event
      end
      it "destroys the requested event" do
        expect {
          delete :destroy, {:id => @event.to_param}
        }.to change(Event, :count).by(-1)
      end

      it "redirects to the events list" do
        delete :destroy, {:id => @event.to_param}
        expect(response).to redirect_to(events_url)
      end
    end
  
  end
end

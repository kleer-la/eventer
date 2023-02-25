# frozen_string_literal: true

require 'rails_helper'
require_relative '../support/devise'

describe EventsController do
  context 'the user is a admin' do
    login_admin

    describe 'GET new' do
      it 'assigns a new event as @event' do
        get :new
        expect(assigns(:event)).to be_a_new(Event)
      end
    end
  end

  context 'the user is a comercial' do
    login_comercial

    describe 'GET index' do
      it 'assigns all events as @events' do
        event = FactoryBot.create(:event)
        get :index
        expect(assigns(:events)).to eq [event]
      end
    end

    describe 'GET show' do
      it 'assigns the requested event as @event' do
        event = FactoryBot.create(:event)
        get :show, params: { id: event.to_param }
        expect(assigns(:event)).to eq event
      end
    end

    describe 'GET new' do
      it 'assigns a new event as @event' do
        get :new
        expect(assigns(:event)).to be_a_new(Event)
      end
    end

    describe 'GET copy' do
      it 'Change the date' do
        event = FactoryBot.create(:event, date: Date.today)
        get :copy, params: { id: event.to_param }
        new_event = assigns(:event)
        expect(response).to render_template(:new)
        expect(new_event.date).to be nil
      end
    end

    describe 'GET edit' do
      it 'assigns the requested event as @event' do
        event = FactoryBot.create(:event)
        get :edit, params: { id: event.to_param }
        expect(assigns(:event)).to eq event
      end
    end

    describe 'POST create' do
      describe 'with valid params' do
        before(:each) do
          event_type = FactoryBot.create(:event_type)
          country = FactoryBot.create(:country)
          trainer = FactoryBot.create(:trainer)
          event = FactoryBot.build(:event,
                                   event_type: event_type,
                                   country: country,
                                   trainer: trainer)
          @event_attr = event.attributes.reject do |k, _v|
            %w[id created_at updated_at average_rating net_promoter_score].include? k
          end
          @event_attr['event_type_id'] = event_type.id.to_s
          @event_attr['country_id'] = country.id.to_s
          @event_attr['trainer_id'] = trainer.id.to_s
        end
        it 'creates a new Event' do
          expect do
            post :create, params: { event: @event_attr }
          end.to change(Event, :count).by(1)
        end

        it 'assigns a newly created event as @event' do
          post :create, params: { event: @event_attr }
          expect(assigns(:event)).to be_a Event
          expect(assigns(:event)).to be_persisted
        end

        it 'redirects to the created event' do
          post :create, params: { event: @event_attr }
          expect(response).to redirect_to(events_path)
        end
      end

      describe 'with invalid params' do
        before(:each) do
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Event).to receive(:save).and_return(false)
          post :create, params: { event: FactoryBot.attributes_for(:event) }
        end
        it 'assigns a newly created but unsaved event as @event' do
          expect(assigns(:event)).to be_a_new(Event)
        end

        it "re-renders the 'new' template" do
          expect(assigns(:event)).to render_template('new')
        end
      end
    end

    describe 'PUT update' do
      describe 'with valid params' do
        before(:each) do
          @event = FactoryBot.create :event
        end

        it 'ok w/o change' do
          put :update, params: { id: @event.to_param, event: @event.attributes }
          expect(assigns(:event)).to eq @event
          expect(response).to redirect_to(events_path)
          expect(flash[:notice]).to include 'modificado'
        end
        it '@event cancelled' do
          put :update, params: { id: @event.to_param, event: { cancelled: true } }
          expect(response).to redirect_to(events_path)
          expect(flash[:notice]).to include 'cancelado'
        end
      end

      describe 'with invalid params' do
        before(:each) do
          @event = FactoryBot.create :event
          allow_any_instance_of(Event).to receive(:save).and_return(false)
          put :update, params: { id: @event.to_param, event: FactoryBot.attributes_for(:event) }
        end
        it 'assigns the event as @event' do
          expect(assigns(:event)).to eq @event
        end

        it "re-renders the 'edit' template" do
          expect(response).to render_template(:edit)
        end
      end
    end

    describe 'DELETE destroy' do
      before(:each) do
        @event = FactoryBot.create :event
      end
      it 'destroys the requested event' do
        expect do
          delete :destroy, params: { id: @event.to_param }
        end.to change(Event, :count).by(-1)
      end

      it 'redirects to the events list' do
        delete :destroy, params: { id: @event.to_param }
        expect(response).to redirect_to(events_url)
      end
    end
  end

  describe 'GET send_certificate' do
    login_admin
    it 'one present' do
      participant = FactoryBot.create(:participant)
      participant.attend!
      participant.save!

      get :send_certificate, params: { id: participant.event.to_param }
      expect(response).to have_http_status :ok
      expect(flash[:notice]).to include '1 certificados'
    end
    it 'one certified' do
      participant = FactoryBot.create(:participant)
      participant.certify!
      participant.save!

      get :send_certificate, params: { id: participant.event.to_param }
      expect(response).to have_http_status :ok
      expect(flash[:notice]).to include '1 certificados'
    end
    # it "abort when trainer has no signature" do
    #   participant= FactoryBot.create(:participant)
    #   participant.attend!
    #   participant.save!
    #   trainer= participant.event.trainer
    #   trainer.signature_image= nil
    #   trainer.save!

    #   get :send_certificate, {:id => participant.event.to_param}
    #   # expect(response).to redirect_to(events_url)
    #   expect(response).to have_http_status :ok
    # end
  end
end

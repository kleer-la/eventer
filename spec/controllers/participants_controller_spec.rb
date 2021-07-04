require 'rails_helper'
require_relative "../support/devise"

describe ParticipantsController do
  
  context "the user is a comercial" do
    login_comercial
    before(:each) do
      @participant = FactoryBot.create(:participant) 
    end
    describe "GET index" do
      it "assigns all participants as @participants" do
        get :index, params: {:event_id => @participant.event.id}
        expect(assigns(:participants)).to eq [@participant]
      end
    end

    describe "GET show" do
      it "assigns the requested participant as @participant" do
        get :show, params: {:id => @participant.to_param, :event_id => @participant.event.id}
        expect(assigns(:participant)).to eq @participant
      end
    end

    describe "GET new" do
      it "assigns a new participant as @participant" do
        get :new, params: {:event_id => @participant.event.id}
        expect(assigns(:participant)).to be_a_new(Participant)
      end
    end

    describe "GET edit" do
      it "assigns the requested participant as @participant" do
        get :edit, params: {:id => @participant.to_param, :event_id => @participant.event.id}
        expect(assigns(:participant)).to eq @participant
      end
    end

    describe "POST create" do
      before(:each) do
        @participant_attr= @participant.attributes.reject {|k,v| 
          %w(id created_at updated_at verification_code campaign_id campaign_source_id konline_po_number pay_notes).include? k}
      end
      describe "with valid params" do
        it "creates a new Participant" do
          expect {
            post :create, params: {:participant => @participant_attr, :event_id => @participant.event.id}
          }.to change(Participant, :count).by(1)
        end

        it "assigns a newly created participant as @participant" do
          post :create, params: {:participant => @participant_attr, :event_id => @participant.event.id}
          expect(assigns(:participant)).to be_a Participant
          expect(assigns(:participant)).to be_persisted
        end

        it "redirects to the created participant" do
          post :create, params: {:participant => @participant_attr, :event_id => @participant.event.id}
          expect(response).to redirect_to( "/events/" + Participant.last.event.id.to_s + "/participant_confirmed" )
        end

        it "persist comment has the first note" do
          @participant_attr[:notes] = "Some question"
          expect {
            post :create, params: {:participant => @participant_attr, :event_id => @participant.event.id}
          }.to change(Participant, :count).by(1)
          expect(assigns(:participant)[:notes]).to match /^Some question$/
        end
      end

      describe "with invalid params" do
        before(:each) do 
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Participant).to receive(:save).and_return(false)
          post :create, params: {:participant => FactoryBot.attributes_for(:participant), :event_id => @participant.event.id}
        end
        it "assigns a newly created but unsaved participant as @participant" do
          expect(assigns(:participant)).to be_a_new Participant
        end

        it "re-renders the 'new' template" do
          expect(response).to render_template("new")
        end
      end
    end

    describe "PUT update" do
      before(:each) do
        @participant_attr= @participant.attributes.reject {|k,v| 
          %w(id created_at updated_at verification_code campaign_id campaign_source_id konline_po_number pay_notes).include? k}
      end
      describe "with valid params" do
        it "assigns the requested participant as @participant" do
          put :update, params: {:id => @participant.to_param, :participant => @participant_attr, :event_id => @participant.event.id}
          expect(assigns(:participant)).to eq @participant
        end

        it "redirects to the participant" do
          put :update, params: {:id => @participant.to_param, :participant => @participant_attr, :event_id => @participant.event.id}
          expect(response).to redirect_to( "/events/" + Participant.last.event.id.to_s + "/participants" )
        end
      end

      describe "with invalid params" do
        before(:each) do 
          allow_any_instance_of(Participant).to receive(:save).and_return(false)
          put :update, params: {:id => @participant.to_param, :participant => FactoryBot.attributes_for(:participant), :event_id => @participant.event}
        end
        it "assigns the participant as @participant" do
          expect(assigns(:participant)).to eq @participant
        end

        it "re-renders the 'edit' template" do
          expect(response).to render_template(:edit)
        end
      end
    end

    describe "DELETE destroy" do
      it "destroys the requested participant" do
        expect {
          delete :destroy, params: {:id => @participant.to_param, :event_id => @participant.event.id}
        }.to change(Participant, :count).by(-1)
      end

      it "redirects to the participants list" do
        delete :destroy, params: {:id => @participant.to_param, :event_id => @participant.event.id}
        expect(response).to redirect_to( "/events/" + @participant.event.id.to_s + "/participants")
      end
    end

    describe "search a participant" do
      it 'By last name' do
        get :search, params: {:name => @participant[:fname]}
        expect(assigns(:participants)).to eq [@participant]
      end
    end

    describe "print attendance sheet" do
      it "A message is shown when no participant is confirmed" do
        get :print,params: {:event_id => @participant.event.id}
        expect(assigns(:participants)).to eq []
      end

      it "A confirmed participant is shown" do
        @participant.confirm!
        @participant.save!
        get :print, params: {:event_id => @participant.event.id}
        expect(assigns(:participants)).to eq [@participant]
        expect(response).to render_template("print")
      end
    end

    describe "batch load" do
      it "Load one" do
        expect {
          post :batch_load, params: {:event_id => @participant.event.id,
            :influence_zone_id => 1,
            :status => 2,
            :participants_batch => "tra,la,la@lan.cl,--"
          }
        }.to change(Participant, :count).by(1)

        expect(response).to redirect_to(event_participants_path)
        expect(flash[:alert]).to include "0 líneas erroneas"
        expect(flash[:notice]).to include "1 participantes creados exitosament"
      end
    end

    describe "Survey" do
      it "w/o attended participant" do 
        get :survey, params: {:event_id => @participant.event.id}
        expect(assigns(:participants)).to match_array([])
      end
      it "w/o an attended participant" do
        @participant.attend!
        @participant.save! 
        get :survey, params: {:event_id => @participant.event.id}
        expect(assigns(:participants)).to match_array([@participant])
      end
    end
    describe "certificate" do
      before(:each) do
        ev= @participant.event.event_type
        @participant.attend!
        @participant.save! 
      end
      it "show one certifcate" do 
        get :certificate,  params: {
          :event_id => @participant.event.id, :id => @participant.id,
          :page_size => "A4", :verification_code => @participant.verification_code,
          :format => :pdf
        }
        expect(assigns(:certificate).name).to eq 'Juan Carlos Perez Luasó'
        expect(assigns(:certificate_store)).not_to be_nil
      end
      it "a certified participant certifcate" do 
        @participant.certify!
        @participant.save!
        get :certificate,  params: {
          :event_id => @participant.event.id, :id => @participant.id,
          :page_size => "A4", :verification_code => @participant.verification_code,
          :format => :pdf
        }
        expect(assigns(:certificate).name).to eq 'Juan Carlos Perez Luasó'
      end
      context 'invalid' do
        it "w/o signature" do
          t=@participant.event.trainers[0]
          t.signature_image="" 
          t.save!
          get :certificate,  params: {
            :event_id => @participant.event.id, :id => @participant.id,
            :page_size => "A4", :verification_code => @participant.verification_code,
            :format => :pdf
          }
          expect(response).to redirect_to event_participants_path
          expect(flash[:alert]).to include "sin firma"
        end

        it "no page size" do
          get :certificate,  params: {
            :event_id => @participant.event.id, :id => @participant.id,
            # :page_size => "A4",
             :verification_code => @participant.verification_code,
            :format => :pdf
          }
          expect(response).to redirect_to event_participants_path
          expect(flash[:alert]).to include "carta"
        end
        it "wrong page size" do
          get :certificate,  params: {
            :event_id => @participant.event.id, :id => @participant.id,
            :page_size => "pepepepe",
             :verification_code => @participant.verification_code,
            :format => :pdf
          }
          expect(response).to redirect_to event_participants_path
          expect(flash[:alert]).to include "carta"
        end
        it "wrong verification code" do
          get :certificate,  params: {
            :event_id => @participant.event.id, :id => @participant.id,
            :page_size => "A4",
             :verification_code => "5BA4365pepeB443ED1801C57",
            :format => :pdf
          }
          expect(response).to redirect_to event_participants_path
          expect(flash[:alert]).to include "verificación"
        end
  
        it "not present (contacted)" do
          @participant.status='N'
          @participant.save! 
  
          get :certificate,  params: {
            :event_id => @participant.event.id, :id => @participant.id,
            :page_size => "A4",
             :verification_code => @participant.verification_code,
            :format => :pdf
          }
          expect(response).to redirect_to event_participants_path
          expect(flash[:alert]).to include "presente"
        end
      end

    end
  end

end

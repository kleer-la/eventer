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
        get :index, {:event_id => @participant.event.id}
        expect(assigns(:participants)).to eq [@participant]
      end
    end

    describe "GET show" do
      it "assigns the requested participant as @participant" do
        get :show, {:id => @participant.to_param, :event_id => @participant.event.id}
        expect(assigns(:participant)).to eq @participant
      end
    end

    describe "GET new" do
      it "assigns a new participant as @participant" do
        get :new, {:event_id => @participant.event.id}
        expect(assigns(:participant)).to be_a_new(Participant)
      end
    end

    describe "GET edit" do
      it "assigns the requested participant as @participant" do
        get :edit, {:id => @participant.to_param, :event_id => @participant.event.id}
        expect(assigns(:participant)).to eq @participant
      end
    end

    describe "POST create" do
      before(:each) do
        @participant_attr= @participant.attributes.reject {|k,v| 
          %w(id created_at updated_at verification_code campaign_id campaign_source_id konline_po_number pay_notes).include? k}
        # @participant_att[:trainer_ids] = [trainer.id.to_s]
      end
      describe "with valid params" do
        it "creates a new Participant" do
          expect {
            post :create, {:participant => @participant_attr, :event_id => @participant.event.id.to_s}
          }.to change(Participant, :count).by(1)
        end

        it "assigns a newly created participant as @participant" do
          post :create, {:participant => @participant_attr, :event_id => @participant.event.id.to_s}
          expect(assigns(:participant)).to be_a Participant
          expect(assigns(:participant)).to be_persisted
        end

        it "redirects to the created participant" do
          post :create, :participant => @participant_attr, :event_id => @participant.event.id.to_s
          expect(response).to redirect_to( "/events/" + Participant.last.event.id.to_s + "/participant_confirmed" )
        end

        it "persist comment has the first note" do
          @participant_attr[:notes] = "Some question"
          expect {
            post :create, :participant => @participant_attr, :event_id => @participant.event.id.to_s
          }.to change(Participant, :count).by(1)
          expect(assigns(:participant)[:notes]).to match /^Some question$/
        end
      end

      describe "with invalid params" do
        before(:each) do 
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Participant).to receive(:save).and_return(false)
          post :create, {:participant => {}, :event_id => @participant.event.id.to_s}          
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
        describe "with valid params" do
          it "updates the requested participant" do
            # Assuming there are no other participants in the database, this
            # specifies that the Participant created on the previous line
            # receives the :update_attributes message with whatever params are
            # submitted in the request.
            expect_any_instance_of(Participant).to receive(:update_attributes).with({'these' => 'params'})
            put :update, {:id => @participant.to_param, :participant => {'these' => 'params'}, :event_id => @participant.event.id }
          end

          # it "assigns the requested participant as @participant" do
          #   put :update, {:id => @participant.to_param, :participant => @participant_attr, :event_id => @participant.event.id.to_s}
          #   expect(assigns(:participant)).to eq @participant
          # end

#           it "redirects to the participant" do
#             participant = Participant.create! valid_attributes
#             put :update, {:id => participant.to_param, :participant => valid_attributes, :event_id => valid_attributes[:event_id]}
#             response.should redirect_to( "/events/" + Participant.last.event.id.to_s + "/participants" )
#           end
        end

#         describe "with invalid params" do
#           it "assigns the participant as @participant" do
#             participant = Participant.create! valid_attributes
#             # Trigger the behavior that occurs when invalid params are submitted
#             Participant.any_instance.stub(:save).and_return(false)
#             put :update, {:id => participant.to_param, :participant => {}, :event_id => valid_attributes[:event_id]}
#             assigns(:participant).should eq(participant)
#           end

#           it "re-renders the 'edit' template" do
#             participant = Participant.create! valid_attributes
#             # Trigger the behavior that occurs when invalid params are submitted
#             Participant.any_instance.stub(:save).and_return(false)
#             put :update, {:id => participant.to_param, :participant => {}, :event_id => valid_attributes[:event_id]}
#             response.should render_template("edit")
#           end
#         end
      end

#       describe "DELETE destroy" do
#         it "destroys the requested participant" do
#           participant = Participant.create! valid_attributes
#           expect {
#             delete :destroy, {:id => participant.to_param, :event_id => participant.event.id}
#           }.to change(Participant, :count).by(-1)
#         end

#         it "redirects to the participants list" do
#           participant = Participant.create! valid_attributes
#           delete :destroy, {:id => participant.to_param, :event_id => participant.event.id}
#           response.should redirect_to( "/events/" + participant.event.id.to_s + "/participants"  )
#         end
#       end

#       describe "search a participant" do
#         it 'By last name' do
#           participant = Participant.create! valid_attributes
#           get :search, {:name => 'Pica'}
#           assigns(:participants).should eq([participant])
#         end
#       end

#       describe "print attendance sheet" do
#         before(:each) do
#           @participant = Participant.create! valid_attributes
#         end
#         it "A message is shown when no participant is confirmed" do
#           get :print, {:event_id => @participant.event.id}
#           assigns(:participants).should eq([])
#         end

#         it "A confirmed participant is shown" do
#           @participant.confirm!
#           @participant.save!
#           get :print, {:event_id => @participant.event.id}
#           assigns(:participants).should eq([@participant])
#           response.should render_template("print")
#         end
#         it "A confirmed participant is shown" do
#           @participant.attend!
#           @participant.save!
#           get :print, {:event_id => @participant.event.id}
#           assigns(:participants).should eq([@participant])
#           response.should render_template("print")
#         end
#       end

    end

end

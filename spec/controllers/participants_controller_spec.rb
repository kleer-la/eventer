require 'spec_helper'

describe ParticipantsController do

  # This should return the minimal set of attributes required to create a valid
  # Participant. As you add validations to Participant, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    { :event_id => FactoryGirl.create(:event).id,
      :fname => "Pablo",
      :lname => "Picasso",
      :email => "ppicaso@pintores.org",
      :phone => "1234-5678",
      :influence_zone_id => FactoryGirl.create(:influence_zone).id}
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # ParticipantsController. Be sure to keep this updated too.
  def valid_session
    nil
  end

  context "the user is a comercial" do

    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      @user = FactoryGirl.create(:comercial)
      sign_in @user
    end

      describe "GET index" do
        it "assigns all participants as @participants" do
          participant = Participant.create! valid_attributes
          get :index, {:event_id => participant.event.id}, valid_session
          assigns(:participants).should eq([participant])
        end
      end

      describe "GET show" do
        it "assigns the requested participant as @participant" do
          participant = Participant.create! valid_attributes
          get :show, {:id => participant.to_param, :event_id => participant.event.id}, valid_session
          assigns(:participant).should eq(participant)
        end
      end

      describe "GET new" do
        it "assigns a new participant as @participant" do
          participant = Participant.create! valid_attributes
          get :new, {:event_id => participant.event.id}, valid_session
          assigns(:participant).should be_a_new(Participant)
        end
      end

      describe "GET edit" do
        it "assigns the requested participant as @participant" do
          participant = Participant.create! valid_attributes
          get :edit, {:id => participant.to_param, :event_id => participant.event.id}, valid_session
          assigns(:participant).should eq(participant)
        end
      end

      describe "POST create" do
        describe "with valid params" do
          it "creates a new Participant" do
            expect {
              post :create, :participant => valid_attributes, :event_id => valid_attributes[:event_id]
            }.to change(Participant, :count).by(1)
          end

          it "assigns a newly created participant as @participant" do
            post :create, :participant => valid_attributes, :event_id => valid_attributes[:event_id]
            assigns(:participant).should be_a(Participant)
            assigns(:participant).should be_persisted
          end

          it "redirects to the created participant" do
            post :create, :participant => valid_attributes, :event_id => valid_attributes[:event_id]
            response.should redirect_to( "/events/" + Participant.last.event.id.to_s + "/participant_confirmed" )
          end

          it "persist comment has the first note" do
            va= valid_attributes
            va[:notes] = "Some question"
            expect {
              post :create, :participant => va, :event_id => valid_attributes[:event_id]
            }.to change(Participant, :count).by(1)
            assigns(:participant)[:notes].should =~ /^Some question$/
          end
        end

        describe "with invalid params" do
          it "assigns a newly created but unsaved participant as @participant" do
            # Trigger the behavior that occurs when invalid params are submitted
            Participant.any_instance.stub(:save).and_return(false)
            post :create, {:participant => {}, :event_id => valid_attributes[:event_id]}, valid_session
            assigns(:participant).should be_a_new(Participant)
          end

          it "re-renders the 'new' template" do
            # Trigger the behavior that occurs when invalid params are submitted
            Participant.any_instance.stub(:save).and_return(false)
            post :create, {:participant => {}, :event_id => valid_attributes[:event_id]}, valid_session
            response.should render_template("new")
          end
        end
      end

      describe "PUT update" do
        describe "with valid params" do
          it "updates the requested participant" do
            participant = Participant.create! valid_attributes
            # Assuming there are no other participants in the database, this
            # specifies that the Participant created on the previous line
            # receives the :update_attributes message with whatever params are
            # submitted in the request.
            Participant.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
            put :update, {:id => participant.to_param, :participant => {'these' => 'params'}, :event_id => participant.event.id }, valid_session
          end

          it "assigns the requested participant as @participant" do
            participant = Participant.create! valid_attributes
            put :update, {:id => participant.to_param, :participant => valid_attributes, :event_id => valid_attributes[:event_id]}, valid_session
            assigns(:participant).should eq(participant)
          end

          it "redirects to the participant" do
            participant = Participant.create! valid_attributes
            put :update, {:id => participant.to_param, :participant => valid_attributes, :event_id => valid_attributes[:event_id]}, valid_session
            response.should redirect_to( "/events/" + Participant.last.event.id.to_s + "/participants" )
          end
        end

        describe "with invalid params" do
          it "assigns the participant as @participant" do
            participant = Participant.create! valid_attributes
            # Trigger the behavior that occurs when invalid params are submitted
            Participant.any_instance.stub(:save).and_return(false)
            put :update, {:id => participant.to_param, :participant => {}, :event_id => valid_attributes[:event_id]}, valid_session
            assigns(:participant).should eq(participant)
          end

          it "re-renders the 'edit' template" do
            participant = Participant.create! valid_attributes
            # Trigger the behavior that occurs when invalid params are submitted
            Participant.any_instance.stub(:save).and_return(false)
            put :update, {:id => participant.to_param, :participant => {}, :event_id => valid_attributes[:event_id]}, valid_session
            response.should render_template("edit")
          end
        end
      end

      describe "DELETE destroy" do
        it "destroys the requested participant" do
          participant = Participant.create! valid_attributes
          expect {
            delete :destroy, {:id => participant.to_param, :event_id => participant.event.id}, valid_session
          }.to change(Participant, :count).by(-1)
        end

        it "redirects to the participants list" do
          participant = Participant.create! valid_attributes
          delete :destroy, {:id => participant.to_param, :event_id => participant.event.id}, valid_session
          response.should redirect_to( "/events/" + participant.event.id.to_s + "/participants"  )
        end
      end

      describe "search a participant" do
        it 'By last name' do
          participant = Participant.create! valid_attributes
          get :search, {:name => 'Pica'}, valid_session
          assigns(:participants).should eq([participant])
        end
      end

      describe "print attendance sheet" do
        it "A message is shown when no participant is confirmed" do
          participant = Participant.create! valid_attributes
          get :print, {:event_id => participant.event.id}, valid_session
          assigns(:participants).should eq([])
        end

        it "A confirmed participant is shown" do
          participant = Participant.create! valid_attributes
          participant.confirm!
          participant.save!
          get :print, {:event_id => participant.event.id}, valid_session
          assigns(:participants).should eq([participant])
          response.should render_template("print")
        end
        it "A confirmed participant is shown" do
          participant = Participant.create! valid_attributes
          participant.attend!
          participant.save!
          get :print, {:event_id => participant.event.id}, valid_session
          assigns(:participants).should eq([participant])
          response.should render_template("print")
        end
      end
    end

end

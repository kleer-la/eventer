require 'rails_helper'
require_relative "../support/devise"

describe TrainersController do
  login_admin

  before(:each) do
    @trainer= FactoryBot.create(:trainer)
  end

  describe "GET index" do
    it "assigns all trainers as @trainers" do
      get :index
      expect(assigns(:trainers)).to eq [@trainer]
    end
  end

  describe "GET show" do
    it "assigns the requested trainer as @trainer" do
      get :show, params: {:id => @trainer.to_param}
      expect(assigns(:trainer)).to eq @trainer
    end
  end

  describe "GET new" do
    it "assigns a new trainer as @trainer" do
      get :new
      expect(assigns(:trainer)).to be_a_new Trainer
    end
  end

  describe "GET edit" do
    it "assigns the requested trainer as @trainer" do
      get :edit, params: {:id => @trainer.to_param}
      expect(assigns(:trainer)).to eq @trainer
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Trainer" do
        expect {
          post :create, params: {:trainer => @trainer.attributes}
        }.to change(Trainer, :count).by(1)
      end

      it "assigns a newly created trainer as @trainer" do
        post :create, params: {:trainer => @trainer.attributes}
        expect(assigns(:trainer)).to be_a Trainer
        expect(assigns(:trainer)).to be_persisted
      end

      it "redirects to the created trainer" do
        post :create, params: {:trainer => @trainer.attributes}
        expect(response).to redirect_to trainers_path
      end
    end

    describe "with invalid params" do
      before(:each) do 
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Trainer).to receive(:save).and_return(false)
        post :create, params: {:trainer => @trainer.attributes}
      end
      it "assigns a newly created but unsaved trainer as @trainer" do
        expect(assigns(:trainer)).to be_a_new Trainer
      end

      it "re-renders the 'new' template" do
        expect(response).to render_template :new
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "assigns the requested trainer as @trainer" do
        put :update, params: {:id => @trainer.to_param, :trainer => @trainer.attributes}
        expect(assigns(:trainer)).to eq @trainer
      end

      it "redirects to the trainer" do
        put :update, params: {:id => @trainer.to_param, :trainer => @trainer.attributes}
        expect(response).to redirect_to trainers_path
      end
    end

    describe "with invalid params" do
      before(:each) do 
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Trainer).to receive(:save).and_return(false)
        put :update, params:{:id => @trainer.to_param, :trainer => @trainer.attributes}
      end
      it "assigns the trainer as @trainer" do
        expect(assigns(:trainer)).to eq @trainer
      end

      it "re-renders the 'edit' template" do
        expect(response).to render_template :edit
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested trainer" do
      expect {
        delete :destroy, params: {:id => @trainer.to_param}
      }.to change(Trainer, :count).by(-1)
    end

    it "redirects to the trainers list" do
      delete :destroy, params: {:id => @trainer.to_param}
      expect(response).to redirect_to trainers_url
    end
  end

end

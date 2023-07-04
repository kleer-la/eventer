# frozen_string_literal: true

require 'rails_helper'
require_relative '../support/devise'

describe EventTypesController do
  login_admin
  before(:all) do
    FileStoreService.create_null
  end
  describe 'GET index' do
    it 'assigns all event_types as @event_types' do
      event_type = FactoryBot.create(:event_type)
      get :index
      expect(assigns(:event_types)).to eq [event_type]
    end
  end

  describe 'GET show' do
    it 'assigns the requested event_type as @event_type' do
      event_type = FactoryBot.create(:event_type)
      get :show, params: { id: event_type.to_param }
      expect(assigns(:event_type)).to eq event_type
    end
  end

  describe 'GET new' do
    it 'assigns a new event_type as @event_type' do
      get :new
      expect(assigns(:event_type)).to be_a_new(EventType)
    end
  end

  describe 'GET edit' do
    it 'assigns the requested event_type as @event_type' do
      event_type = FactoryBot.create(:event_type)
      get :edit, params: { id: event_type.to_param }
      expect(assigns(:event_type)).to eq event_type
    end
  end

  describe 'POST create' do
    before(:each) do
      trainer = FactoryBot.create(:trainer)
      category = FactoryBot.create(:category)
      event_type = FactoryBot.build(:event_type, trainer_ids: [trainer.id.to_s], category_ids: [])
      @event_type_att = event_type.attributes.reject do |k, _v|
        %w[id created_at updated_at average_rating net_promoter_score surveyed_count promoter_count].include? k
      end
      @event_type_att[:trainer_ids] = [trainer.id.to_s]
      @event_type_att[:category_ids] = [category.id.to_s]
    end
    describe 'with valid params' do
      it 'creates a new EventType' do
        expect do
          post :create, params: { event_type: @event_type_att }
        end.to change(EventType, :count).by(1)
      end

      it 'assigns a newly created event_type as @event_type' do
        post :create, params: { event_type: @event_type_att }
        expect(assigns(:event_type)).to be_a EventType
        expect(assigns(:event_type)).to be_persisted
      end

      it 'deleted' do
        @event_type_att[:deleted] = true
        post :create, params: { event_type: @event_type_att }
        expect(assigns(:event_type)[:deleted]).to be true
      end
      it 'noindex' do
        @event_type_att[:noindex] = true
        post :create, params: { event_type: @event_type_att }
        expect(assigns(:event_type)[:noindex]).to be true
      end
      it 'cover' do
        @event_type_att[:cover] = 'rambandanga'
        post :create, params: { event_type: @event_type_att }
        expect(assigns(:event_type)[:cover]).to eq 'rambandanga'
      end
      it 'v2022 fields side_image brochure new_version' do
        @event_type_att[:new_version] = true
        @event_type_att[:side_image] = 'zandanga'
        @event_type_att[:brochure] = 'ajdasd'
        post :create, params: { event_type: @event_type_att }
        expect(assigns(:event_type)[:new_version]).to be true
        expect(assigns(:event_type)[:side_image]).to eq 'zandanga'
        expect(assigns(:event_type)[:brochure]).to eq 'ajdasd'
      end

      it 'redirects to the created event_type' do
        post :create, params: { event_type: @event_type_att }
        expect(response).to redirect_to EventType
      end
    end

    describe 'with invalid params' do
      before(:each) do
        event_type = FactoryBot.create(:event_type)
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(EventType).to receive(:save).and_return(false)
        post :create, params: { event_type: event_type.attributes }
      end
      it 'assigns a newly created but unsaved event_type as @event_type' do
        expect(assigns(:event_type)).to be_a_new(EventType)
      end

      it "re-renders the 'new' template" do
        expect(response).to render_template('new')
      end
    end
  end

  describe 'PUT update' do
    describe 'with valid params' do
      before(:each) do
        @event_type = FactoryBot.create :event_type
      end

      it 'assigns the requested event_type as @event_type' do
        put :update, params: { id: @event_type.to_param, event_type: @event_type.attributes }
        expect(assigns(:event_type)).to eq @event_type
        expect(response).to redirect_to(event_types_path)
        expect(flash[:notice]).to include 'modificado'
      end
    end

    describe 'with invalid params' do
      before(:each) do
        @event_type = FactoryBot.create :event_type
        allow_any_instance_of(EventType).to receive(:save).and_return(false)
        put :update, params: { id: @event_type.to_param, event_type: @event_type.attributes }
      end
      it 'assigns the event_type as @event_type' do
        expect(assigns(:event_type)).to eq @event_type
      end

      it "re-renders the 'edit' template" do
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'DELETE destroy' do
    before(:each) do
      @event_type = FactoryBot.create :event_type
    end
    it 'destroys the requested event_type' do
      # -1
      expect do
        delete :destroy, params: { id: @event_type.to_param }
      end.to change(EventType, :count).by(0)
    end

    it 'redirects to the event_types list' do
      delete :destroy, params: { id: @event_type.to_param }
      expect(response).to redirect_to(event_types_url)
    end
  end

  describe 'GET testimonies' do
    it '@event_type && @participants' do
      event_type = FactoryBot.create(:event_type)
      get :testimonies, params: { id: event_type.to_param }
      expect(assigns(:event_type)).to eq event_type
      expect(assigns(:participants)).to eq []
    end
  end
end

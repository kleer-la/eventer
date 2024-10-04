# frozen_string_literal: true

require 'rails_helper'
require_relative '../support/devise'

describe ResourcesController do
  login_admin

  before(:each) do
    @resource = FactoryBot.create(:resource)
  end

  describe 'GET index' do
    it 'assigns all resources as @resources' do
      get :index
      expect(assigns(:resources)).to eq [@resource]
    end
  end

  describe 'GET new' do
    it 'assigns a new resource as @resource' do
      get :new
      expect(assigns(:resource)).to be_a_new Resource
    end
  end

  describe 'GET edit' do
    it 'assigns the requested resource as @resource' do
      get :edit, params: { id: @resource.to_param }
      expect(assigns(:resource)).to eq @resource
    end
  end

  describe 'POST create' do
    describe 'with valid params' do
      let(:valid_attributes) { FactoryBot.attributes_for(:resource) }

      it 'creates a new resource' do
        expect do
          post :create, params: { resource: valid_attributes }
        end.to change(Resource, :count).by(1)
      end

      it 'assigns a newly created resource as @resource' do
        post :create, params: { resource: valid_attributes }
        expect(assigns(:resource)).to be_a Resource
        expect(assigns(:resource)).to be_persisted
      end

      it 'redirects to the created resource' do
        post :create, params: { resource: valid_attributes }
        expect(response).to redirect_to edit_resource_path(Resource.last)
      end
    end

    describe 'new fields' do
      it 'buyit' do
        resource = FactoryBot.build(:resource, buyit_es: 'url es', buyit_en: 'url en')
        post :create, params: { resource: resource.attributes }
        expect(assigns(:resource)[:buyit_es]).to eq 'url es'
        expect(assigns(:resource)[:buyit_en]).to eq 'url en'
      end
    end
    describe 'with invalid params' do
      before(:each) do
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Resource).to receive(:save).and_return(false)
        post :create, params: { resource: @resource.attributes }
      end
      it 'assigns a newly created but unsaved resource as @resource' do
        expect(assigns(:resource)).to be_a_new Resource
      end

      it "re-renders the 'new' template" do
        expect(response).to render_template :new
      end
    end
  end

  describe 'PUT update' do
    describe 'with valid params' do
      it 'assigns the requested resource as @resource' do
        put :update, params: { id: @resource.to_param, resource: @resource.attributes }
        expect(assigns(:resource)).to eq @resource
      end

      it 'redirects to the resource' do
        put :update, params: { id: @resource.to_param, resource: @resource.attributes }
        expect(response).to redirect_to edit_resource_path(@resource)
      end
    end

    describe 'with invalid params' do
      before(:each) do
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Resource).to receive(:save).and_return(false)
        put :update, params: { id: @resource.to_param, resource: @resource.attributes }
      end
      it 'assigns the resource as @resource' do
        expect(assigns(:resource)).to eq @resource
      end

      it "re-renders the 'edit' template" do
        expect(response).to render_template :edit
      end
    end
  end

  # describe 'DELETE destroy' do
  #   it 'destroys the requested resource' do
  #     expect do
  #       delete :destroy, params: { id: @resource.to_param }
  #     end.to change(resource, :count).by(-1)
  #   end

  #   it 'redirects to the resources list' do
  #     delete :destroy, params: { id: @resource.to_param }
  #     expect(response).to redirect_to resources_url
  #   end
  # end
end

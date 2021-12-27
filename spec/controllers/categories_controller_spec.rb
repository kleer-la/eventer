# frozen_string_literal: true

require 'rails_helper'
require_relative '../support/devise'

describe CategoriesController do
  login_admin

  describe 'GET index' do
    it 'assigns all categories as @categories' do
      category = FactoryBot.create(:category)
      get :index, params: {}
      expect(assigns(:categories)).to eq [category]
    end
  end

  describe 'GET show' do
    it 'assigns the requested category as @category' do
      category = FactoryBot.create(:category)
      get :show, params: { id: category.id }
      expect(assigns(:category)).to eq category
    end
  end

  describe 'GET new' do
    it 'assigns a new category as @category' do
      get :new, params: {}
      expect(assigns(:category)).to be_a_new(Category)
    end
  end

  describe 'GET edit' do
    it 'assigns the requested category as @category' do
      category = FactoryBot.create(:category)
      get :edit, params: { id: category.to_param }
      expect(assigns(:category)).to eq category
    end
  end

  describe 'POST create' do
    describe 'with valid params' do
      it 'creates a new Category' do
        expect do
          post :create, params: { category: FactoryBot.attributes_for(:category) }
        end.to change(Category, :count).by(1)
      end

      it 'assigns a newly created category as @category' do
        post :create, params: { category: FactoryBot.attributes_for(:category) }
        expect(assigns(:category)).to be_a Category
        expect(assigns(:category)).to be_persisted
      end

      it 'redirects to the created category' do
        post :create, params: { category: FactoryBot.attributes_for(:category) }
        expect(response).to redirect_to(Category.last)
      end
    end

    describe 'with invalid params' do
      it 'assigns a newly created but unsaved category as @category' do
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Category).to receive(:save).and_return(false)
        post :create, params: { category: FactoryBot.attributes_for(:category) }
        expect(assigns(:category)).to be_a_new(Category)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Category).to receive(:save).and_return(false)
        post :create, params: { category: FactoryBot.attributes_for(:category) }
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'PUT update' do
    describe 'with valid params' do
      before(:each) do
        @category = FactoryBot.create(:category)
      end

      it 'assigns the requested category as @category' do
        put :update, params: { id: @category.to_param, category: FactoryBot.attributes_for(:category) }
        expect(assigns(:category)).to eq @category
      end

      it 'redirects to the category' do
        put :update, params: { id: @category.to_param, category: FactoryBot.attributes_for(:category) }
        expect(response).to redirect_to(@category)
      end
    end

    describe 'with invalid params' do
      before(:each) do
        @category = FactoryBot.create(:category)
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Category).to receive(:save).and_return(false)
        put :update, params: { id: @category.to_param, category: FactoryBot.attributes_for(:category) }
      end
      it 'assigns the category as @category' do
        expect(assigns(:category)).to eq @category
      end
      it "re-renders the 'edit' template" do
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'DELETE destroy' do
    before(:each) do
      @category = FactoryBot.create(:category)
    end
    it 'destroys the requested category' do
      expect do
        delete :destroy, params: { id: @category.to_param }
      end.to change(Category, :count).by(-1)
    end

    it 'redirects to the categories list' do
      delete :destroy, params: { id: @category.to_param }
      expect(response).to redirect_to(categories_url)
    end
  end
end

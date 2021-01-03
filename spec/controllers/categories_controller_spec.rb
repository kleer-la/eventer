require 'rails_helper'
require_relative "../support/devise"

describe CategoriesController do
  login_admin

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # CategoriesController. Be sure to keep this updated too.
  def valid_session
    nil
  end

  describe "GET index" do
    it "assigns all categories as @categories" do
      category = FactoryBot.create(:category)
      get :index, {}, valid_session
      expect(assigns(:categories)).to eq [category]
    end
  end

  describe "GET show" do
    it "assigns the requested category as @category" do
      category = FactoryBot.create(:category)
      get :show, {:id => category.id}, valid_session
      expect(assigns(:category)).to eq category
    end
  end

  describe "GET new" do
    it "assigns a new category as @category" do
      get :new, {}, valid_session
      expect(assigns(:category)).to be_a_new(Category)
    end
  end

  describe "GET edit" do
    it "assigns the requested category as @category" do
      category = FactoryBot.create(:category)
      get :edit, {:id => category.to_param}, valid_session
      expect(assigns(:category)).to eq category
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Category" do
        expect {
          post :create, {:category => FactoryBot.attributes_for(:category)}, valid_session
        }.to change(Category, :count).by(1)
      end

      it "assigns a newly created category as @category" do
        post :create, {:category => FactoryBot.attributes_for(:category)}, valid_session
        expect(assigns(:category)).to be_a Category
        expect(assigns(:category)).to be_persisted
      end

      it "redirects to the created category" do
        post :create, {:category => FactoryBot.attributes_for(:category)}, valid_session
        expect(response).to redirect_to(Category.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved category as @category" do
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Category).to receive(:save).and_return(false)
        post :create, {:category => {}}, valid_session
        expect(assigns(:category)).to be_a_new(Category)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Category).to receive(:save).and_return(false)
        post :create, {:category => {}}, valid_session
        expect(response).to render_template(:new)
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      before(:each) do
        @category = FactoryBot.create(:category)
      end
      it "updates the requested category" do
        category = FactoryBot.create(:category)
        # Assuming there are no other categories in the database, this
        # specifies that the Category created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        expect_any_instance_of(Category).to receive(:update_attributes).with({'these' => 'params'})
        put :update, {:id => @category.to_param, :category => {'these' => 'params'}}, valid_session
      end

      it "assigns the requested category as @category" do
        put :update, {:id => @category.to_param, :category => FactoryBot.attributes_for(:category)}, valid_session
        expect(assigns(:category)).to eq @category
      end

      it "redirects to the category" do
        put :update, {:id => @category.to_param, :category => FactoryBot.attributes_for(:category)}, valid_session
        expect(response).to redirect_to(@category)
      end
    end

    describe "with invalid params" do
      before(:each) do
        @category = FactoryBot.create(:category)
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Category).to receive(:save).and_return(false)
        put :update, {:id => @category.to_param, :category => {}}, valid_session
      end
      it "assigns the category as @category" do
        expect(assigns(:category)).to eq @category
      end 
      it "re-renders the 'edit' template" do  
        expect(response).to render_template(:edit)
      end
    end
  end
  
  describe "DELETE destroy" do
    before(:each) do
      @category = FactoryBot.create(:category)
    end
    it "destroys the requested category" do
      expect {
        delete :destroy, {:id => @category.to_param}, valid_session
      }.to change(Category, :count).by(-1)
    end

    it "redirects to the categories list" do
      delete :destroy, {:id => @category.to_param}, valid_session
      expect(response).to redirect_to(categories_url)
    end
  end

end

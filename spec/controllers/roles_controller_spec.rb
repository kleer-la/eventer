# frozen_string_literal: true

require 'rails_helper'
require_relative '../support/devise'

describe RolesController do
  context 'If user is administrator' do
    login_admin

    before(:each) do
      @role = FactoryBot.create(:comercial_role)
    end
    describe 'GET index' do
      it 'assigns all roles as @roles' do
        get :index
        expect(assigns(:roles).map(&:name)).to match_array %w[administrator comercial]
      end
    end

    describe 'GET show' do
      it 'assigns the requested role as @role' do
        get :show, params: { id: @role.to_param }
        expect(assigns(:role)).to eq @role
      end
    end

    describe 'GET new' do
      it 'assigns a new role as @role' do
        get :new
        expect(assigns(:role)).to be_a_new Role
      end
    end

    describe 'GET edit' do
      it 'assigns the requested role as @role' do
        get :edit, params: { id: @role.to_param }
        expect(assigns(:role)).to eq @role
      end
    end

    describe 'POST create' do
      describe 'with valid params' do
        it 'creates a new Role' do
          expect do
            post :create, params: { role: @role.attributes }
          end.to change(Role, :count).by(1)
        end

        it 'assigns a newly created role as @role' do
          post :create, params: { role: @role.attributes }
          expect(assigns(:role)).to be_a Role
          expect(assigns(:role)).to be_persisted
        end

        it 'redirects to the created role' do
          post :create, params: { role: @role.attributes }
          expect(response).to redirect_to(Role.last)
        end
      end

      it 'invalid params raise error' do
        expect do
          post :create, params: { role: {} }
        end.to raise_error ActionController::ParameterMissing
      end
      it 'assigns a newly created but unsaved role as @role' do
        allow_any_instance_of(Role).to receive(:save).and_return(false)
        post :create, params: { role: @role.attributes }
        expect(assigns(:role)).to be_a_new Role
        expect(response).to render_template('new')
      end
    end

    describe 'PUT update' do
      describe 'with valid params' do
        it 'assigns the requested role as @role' do
          put :update, params: { id: @role.to_param, role: @role.attributes }
          expect(assigns(:role)).to eq @role
        end

        it 'redirects to the role' do
          put :update, params: { id: @role.to_param, role: @role.attributes }
          expect(response).to redirect_to @role
        end
      end

      describe 'with invalid params' do
        before(:each) do
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Role).to receive(:save).and_return(false)
          put :update, params: { id: @role.to_param, role: @role.attributes }
        end
        it 'assigns the role as @role' do
          expect(assigns(:role)).to eq @role
        end

        it "re-renders the 'edit' template" do
          expect(response).to render_template :edit
        end
      end
    end

    describe 'DELETE destroy' do
      it 'destroys the requested role' do
        expect do
          delete :destroy, params: { id: @role.to_param }
        end.to change(Role, :count).by(-1)
      end

      it 'redirects to the roles list' do
        delete :destroy, params: { id: @role.to_param }
        expect(response).to redirect_to roles_url
      end
    end
  end

  context 'If user is not administrator' do
    login_comercial

    before(:each) do
      @role = FactoryBot.create(:comercial_role)
    end
    describe 'GET index' do
      it 'should raise CanCan::AccessDenied' do
        expect { get :index }.to raise_error CanCan::AccessDenied
      end
    end

    describe 'GET show' do
      it 'should raise CanCan::AccessDenied' do
        expect { get :show, params: { id: @role.to_param } }.to raise_error CanCan::AccessDenied
      end
    end

    describe 'GET new' do
      it 'should raise CanCan::AccessDenied' do
        expect { get :new }.to raise_error CanCan::AccessDenied
      end
    end

    describe 'GET edit' do
      it 'should raise CanCan::AccessDenied' do
        expect { get :edit, params: { id: @role.to_param } }.to raise_error CanCan::AccessDenied
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'
require_relative '../support/devise'

describe UsersController do
  context 'If user is not administrator' do
    login_comercial

    describe 'GET index' do
      it 'can read users' do
        get :index
        expect(response).to have_http_status(:success)
      end
    end

    describe 'GET show' do
      it 'can read a user' do
        user = FactoryBot.create(:user)
        get :show, params: { id: user.id }
        expect(response).to have_http_status(:success)
      end
    end

    describe 'GET new' do
      it 'should raise CanCan::AccessDenied' do
        expect { get :new }.to raise_error CanCan::AccessDenied
      end
    end

    describe 'GET edit' do
      it 'should raise CanCan::AccessDenied' do
        expect { get :edit, params: { id: 1 } }.to raise_error CanCan::AccessDenied
      end
    end
  end
end

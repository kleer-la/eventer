# frozen_string_literal: true

require 'rails_helper'
require_relative '../support/devise'

describe OauthTokensController do
  context 'the user is a admin' do
    login_admin

    describe 'GET index' do
      it 'assigns all tokens as @oauth_tokens' do
        oauth_token = FactoryBot.create(:oauth_token)
        get :index
        expect(assigns(:oauth_tokens)).to eq [oauth_token]
      end
    end
  end
end

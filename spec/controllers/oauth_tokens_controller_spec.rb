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

    describe 'GET new, initiates a new token workflow' do
      it 'redirects to the Xero endpoint' do
        expected_redirect = 'https://login.xero.com/identity/connect/authorize?response_type=code' +
                            "&client_id=#{ENV['XERO_CLIENT_ID']}" +
                            "&redirect_uri=#{CGI.escape(ENV['XERO_REDIRECT_URI'])}" +
                            "&scope=#{ENV['XERO_SCOPES'].gsub(' ', '+')}"

        get :new

        expect(response).to redirect_to(expected_redirect)
      end
    end
  end
end

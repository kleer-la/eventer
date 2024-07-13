# frozen_string_literal: true

require 'rails_helper'
require_relative '../support/devise'

describe OauthTokensController do
  context 'the user is a admin' do
    login_admin

    let(:original_env) { {} }
    let(:test_env) do
      {
        'XERO_CLIENT_ID' => 'some',
        'XERO_CLIENT_SECRET' => 'secret',
        'XERO_REDIRECT_URI' => 'data',
        'XERO_SCOPES' => 'definded'
      }
    end

    before do
      # Save original ENV values
      test_env.keys.each { |key| original_env[key] = ENV[key]}
    end

    after do
      # Restore original ENV values
      original_env.each {|key, value| ENV[key] = value}
    end

    describe 'GET index' do
      it 'assigns all tokens as @oauth_tokens' do
        oauth_token = FactoryBot.create(:oauth_token)
        get :index
        expect(assigns(:oauth_tokens)).to eq [oauth_token]
      end
    end

    describe 'new token workflow' do
      it 'redirects to the Xero endpoint' do
        test_env.each {|key, value| ENV[key] = value}     # Set test ENV values
        expected_redirect = 'https://login.xero.com/identity/connect/authorize?response_type=code' \
                            "&client_id=#{ENV['XERO_CLIENT_ID']}" \
                            "&redirect_uri=#{CGI.escape(ENV['XERO_REDIRECT_URI'])}" \
                            "&scope=#{ENV['XERO_SCOPES'].gsub(' ', '+')}"

        get :new

        expect(response).to redirect_to(expected_redirect)
      end
    end
  end
end

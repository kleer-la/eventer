# frozen_string_literal: true

class OauthTokensController < ApplicationController

  def index
    @oauth_tokens = OauthToken.all
    respond_to do |format|
      format.html
    end
  end

  def new
    xero_client = XeroClientHelper.build_client

    redirect_to xero_client.authorization_url
  end

end
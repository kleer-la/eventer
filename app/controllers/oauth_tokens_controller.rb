# frozen_string_literal: true

class OauthTokensController < ApplicationController
  def index
    @oauth_tokens = OauthToken.all
    respond_to do |format|
      format.html
    end
  end

  def new
    xero_client = XeroClientService.build_client

    redirect_to xero_client.authorization_url
  end

  def callback
    xero_client = XeroClientService.build_client

    token_set = xero_client.get_token_set_from_callback(params)

    if token_set['error']
      redirect_to collection_path, notice: "Error generating token. #{token_set['error']}"
    else
      xero_client.set_token_set(token_set)

      oauth_token = OauthToken.first_or_create
      oauth_token.issuer = 'Xero'
      oauth_token.token_set = token_set
      oauth_token.tenant_id = xero_client.connections.last['tenantId']
      oauth_token.save!

      redirect_to oauth_tokens_path, notice: 'Token generated successfully!'
    end
  end
end

# frozen_string_literal: true

class OauthTokensController < ApplicationController

  # GET /articles
  def index
    @oauth_tokens = OauthToken.all
    respond_to do |format|
      format.html
    end
  end

end
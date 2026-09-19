# frozen_string_literal: true

module Handoff
  class TokensController < BaseController
    # Issues (or replaces) the token and renders the account page with it shown
    # once — no redirect, so the token never travels through the session.
    def create
      @user = current_handoff_user
      @token = HandoffToken.issue!(@user)
      @issued = @token.plaintext
      render 'handoff/accounts/show'
    end

    def destroy
      current_handoff_user.active_token&.revoke!
      redirect_to handoff_path, notice: 'Token revocado.'
    end
  end
end

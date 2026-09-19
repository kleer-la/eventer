# frozen_string_literal: true

module Handoff
  # The account page: who you are, your token, this month's usage.
  class AccountsController < BaseController
    def show
      @user = current_handoff_user
      @token = @user.active_token
    end
  end
end

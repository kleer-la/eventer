# frozen_string_literal: true

module Handoff
  # Pages a signed-in HandoffUser sees. Devise's own `authenticate_handoff_user!`
  # would send strangers to a Devise sign-in route this scope does not have.
  class BaseController < ApplicationController
    layout 'handoff'

    before_action :require_handoff_user!

    private

    def require_handoff_user!
      redirect_to handoff_sign_in_path unless handoff_user_signed_in?
    end
  end
end

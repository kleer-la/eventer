# frozen_string_literal: true

module Handoff
  class SessionsController < ApplicationController
    layout 'handoff'

    def new
      redirect_to handoff_path if handoff_user_signed_in?
    end

    def destroy
      sign_out :handoff_user
      redirect_to handoff_sign_in_path
    end
  end
end

# frozen_string_literal: true

module Handoff
  class SessionsController < ApplicationController
    include HandoffLocale

    layout 'handoff'
    around_action :use_handoff_locale

    def new
      session[:handoff_locale] = params[:locale] if params[:locale].present?
      redirect_to handoff_path if handoff_user_signed_in?
    end

    # return_to lets the consent page's "Cambiar de cuenta" come back to the same
    # authorization after a fresh Google login; only an authorization is honoured.
    def destroy
      sign_out :handoff_user
      session['handoff_return_to'] = params[:return_to] if params[:return_to].to_s.start_with?('/oauth/authorize')
      redirect_to handoff_sign_in_path
    end
  end
end

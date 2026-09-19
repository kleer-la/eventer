# frozen_string_literal: true

module Handoff
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def google_oauth2
      user = HandoffUser.from_google(request.env['omniauth.auth'])
      if user
        sign_in user
        # Back to the OAuth authorization an MCP client started, if that is what brought us here
        redirect_to session.delete('handoff_return_to').presence || handoff_path
      else
        redirect_to handoff_sign_in_path, alert: 'Necesitamos una cuenta de Google con el email verificado.'
      end
    end

    def failure
      redirect_to handoff_sign_in_path, alert: 'No pudimos iniciar sesión con Google.'
    end
  end
end

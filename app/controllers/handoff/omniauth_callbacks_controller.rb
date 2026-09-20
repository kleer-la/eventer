# frozen_string_literal: true

module Handoff
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    include HandoffLocale

    around_action :use_handoff_locale

    def google_oauth2
      auth = request.env['omniauth.auth']
      user = HandoffUser.from_google(auth)
      return refuse(auth) unless user

      sign_in user
      # Back to the OAuth authorization an MCP client started, if that is what brought us here
      redirect_to session.delete('handoff_return_to').presence || handoff_path
    end

    def failure
      redirect_to handoff_sign_in_path, alert: t('handoff.sign_in.failed')
    end

    private

    # An unverified email, or a verified one that never requested the resource:
    # the sign-in page says which, and points at the form in this entry's language.
    def refuse(auth)
      unless auth.extra&.raw_info&.email_verified
        return redirect_to handoff_sign_in_path,
                           alert: t('handoff.sign_in.unverified')
      end

      redirect_to handoff_sign_in_path, flash: { not_requested: auth.info.email }
    end
  end
end

# frozen_string_literal: true

# Every handoff page speaks the language the resource was requested in: the
# account's locale once there is an account, the entry point's (/handoff/es,
# /handoff/en) before that, Spanish by default.
module HandoffLocale
  extend ActiveSupport::Concern

  included do
    helper_method :handoff_locale
  end

  def handoff_locale
    params[:locale].presence_in(HandoffUser::LOCALES) ||
      current_handoff_user&.locale ||
      session[:handoff_locale].presence_in(HandoffUser::LOCALES) ||
      'es'
  end

  def use_handoff_locale(&)
    I18n.with_locale(handoff_locale, &)
  end
end

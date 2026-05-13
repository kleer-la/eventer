Rails.application.config.to_prepare do
  %w[SessionsController PasswordsController RegistrationsController
     ConfirmationsController UnlocksController].each do |controller|
    Devise.const_get(controller).layout 'devise'
  end
end

# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Eventer::Application.initialize!

#ActionMailer configuration
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  :address => ENV["KEVENTER_SMTP_ADDRESS"] || "smtp.mandrillapp.com",
  :port => ENV["KEVENTER_SMTP_PORT"]|| 587,
  :user_name => ENV["KEVENTER_SMTP_USERNAME"],
  :password => ENV["KEVENTER_SMTP_PASSWORD"]
}

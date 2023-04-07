require_relative "boot"
require_relative '../app/services/file_store_service.rb'

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Eventer
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    # config.load_defaults 6.0  # test fail :(
    config.autoloader = :zeitwerk # If you need to stick with the defaults of an older Rails version, you can choose to only activate Zeitwerk separate from the Rails 6.0 defaults

    # config.autoload_paths << "#{Rails.root}/app/services"

    # Initialize configuration defaults for originally generated Rails version.
    # config.load_defaults 6.1
    config.load_defaults 7.0

    config.assets.digest = true
    
    config.active_record.legacy_connection_handling = false

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    #x I18n.config.enforce_available_locales = false
    #x I18n.default_locale = :es    
  end
end

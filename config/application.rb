require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Eventer
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    # config.load_defaults 6.0  # test fail :(
    config.autoloader = :zeitwerk # If you need to stick with the defaults of an older Rails version, you can choose to only activate Zeitwerk separate from the Rails 6.0 defaults

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    I18n.config.enforce_available_locales = false
    I18n.default_locale = :es
    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = 'utf-8'  end
end

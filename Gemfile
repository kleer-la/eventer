source 'http://rubygems.org'

ruby '~> 2.7'

gem 'rails', '~> 5.2'

gem 'web-console', '~> 2.0', group: :development
gem 'listen', group: :development

group :development, :test do
  gem 'sqlite3'
  gem 'rspec-rails'
  gem 'pdf-inspector', :require => "pdf/inspector"
  gem 'rspec-mocks'
  gem 'coveralls_reborn', require: false   # https://github.com/lemurheavy/coveralls-ruby/issues/161 (thor>=0.20 => railties >=5.0)
  # gem 'coveralls' #, '~> 0.7', require: false   # https://github.com/lemurheavy/coveralls-ruby/issues/161
  gem 'debase'
  gem 'ruby-debug-ide'
  gem 'database_cleaner-active_record'
end

group :test do
  gem 'factory_bot_rails',require: false
  gem 'cucumber-rails', '< 2.1.0', require: false  # 2.2 if rails >= 5.0? just updating doesn't works
  gem 'capybara'
  gem 'selenium-webdriver' #, '~> 3'
  gem 'webdrivers' #, '~> 4.0'
end

group :test, :production do
  gem 'pg', '~> 1.00'
end

# Gems used only for assets and not required
# in production environments by default.
gem 'sassc-rails'
gem 'coffee-rails', '~> 4' # wait until rails 5.2 to update to 5.0 
                          # cant remove: cannot load such file -- coffee_script sprockets/autoload/coffee_script

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem "therubyracer"
gem 'uglifier', '>= 1.3.0'

gem 'jquery-rails'
gem 'haml'
gem 'haml-rails'

gem 'nokogiri'
gem 'eventmachine', '1.2.7'
# Gemas para idetificación y autorización de usuarios
gem 'devise', '~> 4'
gem 'cancancan'

gem 'formtastic', '~> 3.1' # fail with v4 (bc formtastic-bootstrap) https://github.com/formtastic/formtastic/issues/1308
gem 'formtastic-bootstrap'
gem 'valid_email'
gem 'daemons'
gem 'delayed_job_active_record'
gem 'comma'
gem 'money'
gem 'prawn'
gem 'prawn_rails'
gem 'dimensions' # knowing the heigt of an image - for certificates pdf
gem 'redcarpet'

gem 'best_in_place' # for editing participants

# Amazon AWS API Client
gem 'aws-sdk', '~> 2' # v2 change to Aws instead of AWS

# App Monitoring Heroku Plug-In
gem 'newrelic_rpm'

# Gemas necesarias para integracion con mailchimp workflow
gem 'json'

#reCaptcha
gem "recaptcha", require: "recaptcha/rails"  #, :github => "ambethia/recaptcha"

## Gemfile for Rails 3+, Sinatra, and Merb
gem 'will_paginate', '~> 3'

gem 'responders', '~> 2.0' # for respond_to at the class level (Rails 4.2) used(?) in application_controller
gem 'activemodel-serializers-xml' # to_xml  (rails 5)
gem 'rails-controller-testing'    # assigns (rails 5)
gem 'puma'

gem 'friendly_id' # for blog Articles
def next?
  File.basename(__FILE__) == "Gemfile.next"
end
# frozen_string_literal: true

source 'http://rubygems.org'

ruby '~> 2.7.7'

if next?
  gem 'rails', '~> 6.0.0'
else
  gem 'rails', '~> 5.2'
end

group :development do
  gem 'listen'
  gem 'rubocop'
  gem 'brakeman'
end

group :development, :test do
  # https://github.com/lemurheavy/coveralls-ruby/issues/161 (thor>=0.20 => railties >=5.0)
  gem 'pdf-inspector', require: 'pdf/inspector'
  gem 'rspec-mocks'
  gem 'rspec-rails'
  gem 'sqlite3'
  gem 'database_cleaner-active_record'
  gem 'debase'
  gem 'ruby-debug-ide'
  gem 'next_rails'
  gem 'simplecov'
  gem 'simplecov-lcov', '~> 0.8.0'
end

group :test do
  gem 'capybara'
  gem 'cucumber-rails', require: false
  gem 'factory_bot_rails', require: false
  gem 'selenium-webdriver' # , '~> 3'
  gem 'webdrivers' # , '~> 4.0'
end

group :test, :production do
  gem 'pg', '~> 1.00'
end

# Gems used only for assets and not required
# in production environments by default.
if next?
  gem 'coffee-rails', '~> 5.0'
else
  gem 'coffee-rails', '~> 4' # wait until rails 5.2 to update to 5.0
end
gem 'sassc-rails'
# cant remove: cannot load such file -- coffee_script sprockets/autoload/coffee_script

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer'
gem 'execjs', '~> 2.7.0'    # fail with 2.8.1
gem 'uglifier', '>= 1.3.0'

gem 'haml'
gem 'haml-rails'
gem 'jquery-rails'

gem 'eventmachine', '1.2.7'
gem 'nokogiri'
# Gemas para idetificación y autorización de usuarios
gem 'cancancan'
gem 'devise', '~> 4'

gem 'comma'
gem 'daemons'
gem 'delayed_job_active_record'
gem 'dimensions' # knowing the heigt of an image - for certificates pdf
gem 'formtastic'
gem 'formtastic-bootstrap'
gem 'money'
gem 'prawn'
gem 'prawn_rails'
gem 'redcarpet'
gem 'valid_email'

gem 'best_in_place' # for editing participants

# Amazon AWS API Client
# TODO AWS v3
gem 'aws-sdk', '~> 2' # v2 change to Aws instead of AWS

# App Monitoring Heroku Plug-In
gem 'newrelic_rpm'

# Gemas necesarias para integracion con mailchimp workflow

# reCaptcha
gem 'recaptcha', require: 'recaptcha/rails' # , :github => "ambethia/recaptcha"

## Gemfile for Rails 3+, Sinatra, and Merb
gem 'will_paginate', '~> 3'

gem 'activemodel-serializers-xml' # to_xml  (rails 5)
gem 'puma'
gem 'rails-controller-testing' # assigns (rails 5)

if next?
  gem 'responders', '~> 3.0'
else
  gem 'responders', '~> 2.0' # for respond_to at the class level (Rails 4.2) used(?) in application_controller
end

gem 'friendly_id' # slug for blog Articles

# Xero API
gem 'jwt'
gem 'xero-ruby'

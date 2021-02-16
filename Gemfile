source 'http://rubygems.org'

ruby '~> 2.6'

gem 'rails', '~> 4.2'

gem 'web-console', '~> 2.0', group: :development

group :development, :test do
  gem 'sqlite3', '~> 1.3.6' # '1.4.2'
  gem 'rspec-rails'
  gem 'pdf-inspector', :require => "pdf/inspector"
  gem 'rspec-mocks'
  gem 'simplecov', '~> 0.8'
  gem 'coveralls', require: false
  gem 'debase'
  gem 'ruby-debug-ide'
  gem 'database_cleaner-active_record'
end

group :test do
  gem 'factory_bot_rails',require: false
  gem 'cucumber-rails', '< 2.1', require: false  # 2.2 if rails >= 5.0
  gem 'capybara'
  gem 'shoulda-matchers' #, '~> 3.0' # v3 para ActiveRecord 4
  gem 'selenium-webdriver' #, '~> 3'
  gem 'webdrivers' #, '~> 4.0'
end

group :test, :production do
  gem 'pg', '0.21' # wait until Rails 5.1.5 to upgrade to pg 1.x
end

group :production do
  gem 'rails_12factor'
  gem 'thin'
end

# Gems used only for assets and not required
# in production environments by default.
gem 'sassc-rails'
gem 'coffee-rails', '~> 4'

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

gem 'formtastic'
gem 'formtastic-bootstrap'
gem 'valid_email'
gem 'daemons'
gem 'delayed_job_active_record'
gem 'comma'
gem 'money'
gem 'prawn'
gem 'prawn_rails'
gem 'dimensions' # knowing the heigt of an image
gem 'redcarpet'


# Gemas necesarias para la comunicación con CapsuleCRM
gem 'curb', '0.9.10'

# Edición en el lugar
gem 'best_in_place'

# Amazon AWS API Client
gem 'aws-sdk', '< 2' # v2 change to Aws instead of AWS

# App Monitoring Heroku Plug-In
gem 'newrelic_rpm'

# Gemas necesarias para integracion con mailchimp workflow
gem 'httparty'
gem 'json', '1.8.6'

#reCaptcha
gem "recaptcha", require: "recaptcha/rails"  #, :github => "ambethia/recaptcha"

## Gemfile for Rails 3+, Sinatra, and Merb
gem 'will_paginate', '~> 3'

# Gem for respond_to at the class level (Rails 4.2) used(?) in application_controller
gem 'responders', '~> 2.0'
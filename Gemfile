source 'http://rubygems.org'

ruby '~> 2.3.8'

gem 'rails', '~> 4.0.0'
gem 'test-unit', '~> 3.0'

group :development, :test do
  gem 'sqlite3', '~> 1.3.6' # '1.4.2'
  gem 'rspec-rails'
  gem 'pdf-inspector', :require => "pdf/inspector"

  gem 'rspec-mocks'
  gem 'simplecov', '~> 0.7.1'
  gem 'coveralls', require: false
  # gem "chromedriver-helper"
  gem 'debase'
  gem 'ruby-debug-ide'
  gem 'database_cleaner-active_record'
end

group :test do
  gem 'factory_bot_rails',require: false
  gem 'cucumber-rails', require: false
  gem 'capybara', '~> 2.2' 
  gem 'shoulda-matchers', '~> 3.0' # v3 para ActiveRecord 4
  gem 'selenium-webdriver', '~> 3'
  gem 'webdrivers', '~> 4.0'
end

group :test, :production do
  gem 'pg', '0.21'  
end

group :production do
  gem 'rails_12factor'
  gem 'thin'
  # gem 'sprockets_better_errors'   # only for Rails 4.0.x !!!!
end

# Gems used only for assets and not required
# in production environments by default.
gem 'sass-rails',   '~> 4.0.0'
gem 'coffee-rails', '~> 4.0.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'execjs'
gem "therubyracer"
gem 'uglifier', '>= 1.3.0'

gem 'jquery-rails'
gem 'haml'
gem 'haml-rails'

gem 'nokogiri', '1.6.7.2'
gem 'eventmachine', '1.2.7'
# Gemas para idetificación y autorización de usuarios
gem 'devise', '~> 3.1'
gem 'cancancan'

gem 'formtastic', '~> 2.3'
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
gem 'aws-sdk'

# App Monitoring Heroku Plug-In
gem 'newrelic_rpm'

# Gemas necesarias para integracion con mailchimp workflow
gem 'httparty'
gem 'json', '1.8.6'

#reCaptcha
gem "recaptcha", require: "recaptcha/rails"  #, :github => "ambethia/recaptcha"

## Gemfile for Rails 3+, Sinatra, and Merb
gem 'will_paginate', '~> 3.1.0'

# add these gems to help with the transition:
gem 'protected_attributes'
# gem 'rails-observers'
# gem 'actionpack-page_caching'
# gem 'actionpack-action_caching'
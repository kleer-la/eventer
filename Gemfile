source 'http://rubygems.org'

ruby '~> 2.2.5'

gem 'rails', '~> 3.2.22'

group :development, :test do
  gem 'sqlite3', '~> 1.3.6' # '1.4.2'
  gem 'rspec-rails'
  gem 'pdf-inspector', :require => "pdf/inspector"

  gem "minitest-rails", "~> 1.0"
  gem 'test-unit', '~> 3.0'
  gem 'rspec-mocks'
  gem 'simplecov', '~> 0.7.1'
  gem 'coveralls', require: false
  gem "chromedriver-helper"
  gem 'debase'
  gem 'ruby-debug-ide'
end

group :test do
  gem 'database_cleaner'
  gem 'factory_girl_rails',require: false
  gem 'cucumber-rails', require: false
  gem 'capybara'
  gem 'shoulda-matchers'
  gem 'selenium-webdriver', '~> 2.53.4'
  gem 'pg', '0.20'
end

group :production do
  gem 'pg', '0.20'
  gem 'thin'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'execjs'
  gem "therubyracer"
  gem 'uglifier', '>= 1.0.3'
end


gem 'jquery-rails'
gem 'haml'
gem 'haml-rails'

gem 'nokogiri', '1.6.7.2'
gem 'eventmachine', '1.2.7'
# Gemas para idetificación y autorización de usuarios
gem 'devise', '3.1.0'
gem 'cancan'

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


# frozen_string_literal: true

# Load the Rails application.
require_relative 'application'

# Require New Relic before initializing the Rails application
require 'newrelic_rpm'

# Initialize the Rails application.
Rails.application.initialize!

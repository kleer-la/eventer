# frozen_string_literal: true

# Sprockets 4.x auto-registers a CoffeeScript processor that tries to require
# the coffee_script gem when computing cache keys — even if no .coffee files
# exist. Since we removed coffee-rails, stub the cache_key method to prevent
# LoadError at boot.
Sprockets::CoffeeScriptProcessor.define_singleton_method(:cache_key) { 'coffee-disabled' }

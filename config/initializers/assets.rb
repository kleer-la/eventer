# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

# Devise: If you are deploying Rails 3.1 on Heroku, you may want to set:
# config.assets.initialize_on_precompile = false
# On config/application.rb forcing your application to not access the DB or load models when precompiling your assets.
Rails.application.config.assets.initialize_on_precompile = false

Rails.application.config.public_file_server.enabled = true

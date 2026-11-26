# frozen_string_literal: true

# force_pkce was on from the start (MCP OAuth), but without these columns
# Doorkeeper never stored the code_challenge, so it accepted any code_verifier.
# Doorkeeper 5.9.10 refuses the authorization code flow until they exist.
# From `rails generate doorkeeper:pkce`.
class EnablePkce < ActiveRecord::Migration[8.1]
  def change
    add_column :oauth_access_grants, :code_challenge, :string, null: true
    add_column :oauth_access_grants, :code_challenge_method, :string, null: true
  end
end

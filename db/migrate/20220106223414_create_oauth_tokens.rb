# frozen_string_literal: true

class CreateOauthTokens < ActiveRecord::Migration[5.2]
  def change
    create_table :oauth_tokens do |t|
      t.string :issuer
      t.string :token_set
      t.string :tenant_id

      t.timestamps
    end
  end
end

class CreateOauthTokens < ActiveRecord::Migration[5.2]
  def change
    create_table :oauth_tokens do |t|
      t.string :issuer
      t.string :token_set
      t.string :tenantId

      t.timestamps
    end
  end
end

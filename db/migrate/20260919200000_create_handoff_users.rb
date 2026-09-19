# frozen_string_literal: true

# Accounts for the session-handoff plugin (#201): people outside Kleer who sign
# in with Google to get a personal TTS token. Deliberately not a User: any
# signed-in User reaches the ActiveAdmin dashboard, and these must never.
class CreateHandoffUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :handoff_users do |t|
      t.string :email, null: false
      t.string :name
      t.string :google_uid, null: false

      # Devise :trackable
      t.integer :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip

      t.timestamps
    end
    add_index :handoff_users, :google_uid, unique: true

    # Only the SHA-256 digest is stored; the token itself is shown once, when issued.
    create_table :handoff_tokens do |t|
      t.references :handoff_user, null: false, foreign_key: true
      t.string :digest, null: false
      t.datetime :revoked_at
      t.datetime :last_used_at

      t.timestamps
    end
    add_index :handoff_tokens, :digest, unique: true

    add_index :tts_usages, %i[owner_id created_at]
  end
end

# frozen_string_literal: true

# One row per POST /api/tts/briefing that got past the guards (#199): what it
# cost, never what it said. It is the source of truth for the overuse limits —
# with no Redis and the default cache store, a cache counter would not agree
# between the two web workers — and, later, for a per-user monthly quota (#201).
class CreateTtsUsages < ActiveRecord::Migration[8.1]
  def change
    create_table :tts_usages do |t|
      t.string :status, null: false, default: 'running'
      t.integer :beats_count, null: false, default: 0
      t.integer :chars, null: false, default: 0
      t.integer :synthesis_ms
      # HMAC of the client IP: enough to tell one client from another, not to get
      # the IP back. Per-client limits hang off it until tokens are per user (#201).
      t.string :client_hash, limit: 16
      t.references :owner, foreign_key: false, index: false # the token's owner, once tokens are per user (#201)

      t.timestamps
    end
    add_index :tts_usages, :created_at
    add_index :tts_usages, :status
    add_index :tts_usages, %i[client_hash created_at]
  end
end

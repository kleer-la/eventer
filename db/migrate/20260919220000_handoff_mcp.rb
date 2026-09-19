# frozen_string_literal: true

# The session-handoff MCP connector (#202).
#
# OAuth tokens now say what kind of owner authorized them: until here every
# resource owner was a User; HandoffUser tokens would otherwise collide on id
# with admin accounts. Existing rows are Users.
#
# handoff_briefings holds a synthesized MP3 for the hour its download link
# lives — a tool result cannot carry audio into the chat — and is purged after.
class HandoffMcp < ActiveRecord::Migration[8.1]
  def up
    %i[oauth_access_grants oauth_access_tokens].each do |table|
      add_column table, :resource_owner_type, :string
      execute "UPDATE #{table} SET resource_owner_type = 'User' WHERE resource_owner_id IS NOT NULL"
      add_index table, %i[resource_owner_id resource_owner_type]
    end

    create_table :handoff_briefings do |t|
      t.references :handoff_user, null: false, foreign_key: true
      t.binary :audio, null: false
      t.integer :beats_count, null: false, default: 0
      t.datetime :expires_at, null: false

      t.timestamps
    end
    add_index :handoff_briefings, :expires_at
  end

  def down
    drop_table :handoff_briefings
    %i[oauth_access_grants oauth_access_tokens].each do |table|
      remove_index table, %i[resource_owner_id resource_owner_type]
      remove_column table, :resource_owner_type
    end
  end
end

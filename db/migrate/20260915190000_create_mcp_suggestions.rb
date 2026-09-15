# frozen_string_literal: true

# Backs suggest_mcp_improvement: a place for an MCP session to log friction
# (a missing tool, a guessed output, a workaround) as data instead of a
# one-off remark, so it can be triaged from the admin.
class CreateMcpSuggestions < ActiveRecord::Migration[8.1]
  def change
    create_table :mcp_suggestions do |t|
      t.text :goal
      t.text :friction, null: false
      t.text :proposal
      t.string :tools
      t.integer :status, null: false, default: 0
      t.text :resolution
      t.references :reported_by, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end
    add_index :mcp_suggestions, :status
  end
end

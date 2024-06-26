# frozen_string_literal: true

class AddEmbeddedPlayerToEvent < ActiveRecord::Migration[4.2]
  def up
    add_column :events, :embedded_player, :text
  end

  def down
    remove_column :events, :embedded_player
  end
end

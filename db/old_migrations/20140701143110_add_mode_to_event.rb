# frozen_string_literal: true

class AddModeToEvent < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :mode, :string, limit: 2
  end
end

# frozen_string_literal: true

class AddMaterialsToEventType < ActiveRecord::Migration[4.2]
  def up
    add_column :event_types, :materials, :text
  end

  def down
    remove_column :event_types, :materials
  end
end

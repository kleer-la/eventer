# frozen_string_literal: true

class AddMultipleCategoriesToAnEventType < ActiveRecord::Migration[4.2]
  def self.up
    create_table :categories_event_types, id: false do |t|
      t.references :category, :event_type
    end
  end

  def self.down
    drop_table :categories_event_types
  end
end

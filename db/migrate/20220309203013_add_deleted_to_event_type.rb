# frozen_string_literal: true

class AddDeletedToEventType < ActiveRecord::Migration[5.2]
  def change
    add_column :event_types, :deleted, :boolean, null: false, default: false
    add_column :event_types, :noindex, :boolean, null: false, default: false
  end
end

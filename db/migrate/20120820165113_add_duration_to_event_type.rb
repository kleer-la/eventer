# frozen_string_literal: true

class AddDurationToEventType < ActiveRecord::Migration[4.2]
  def up
    add_column :event_types, :duration, :integer
  end

  def down
    remove_column :event_types, :duration
  end
end

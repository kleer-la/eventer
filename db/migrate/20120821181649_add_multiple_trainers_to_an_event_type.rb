# frozen_string_literal: true

class AddMultipleTrainersToAnEventType < ActiveRecord::Migration[4.2]
  def self.up
    create_table :trainers_event_types, id: false do |t|
      t.references :trainer, :event_type
    end
  end

  def self.down
    drop_table :trainers_event_types
  end
end

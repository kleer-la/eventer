class FixMultipleTrainersEventTypeAssociation < ActiveRecord::Migration
  def self.up
      drop_table :trainers_event_types
      create_table :event_types_trainers, :id => false do |t|
        t.references :trainer, :event_type
      end
    end

    def self.down
      create_table :trainers_event_types, :id => false do |t|
        t.references :trainer, :event_type
      end
      drop_table :event_types_trainers
    end
end

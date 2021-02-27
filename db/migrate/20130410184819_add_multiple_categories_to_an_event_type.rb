class AddMultipleCategoriesToAnEventType < ActiveRecord::Migration
  def self.up
      create_table :categories_event_types, :id => false do |t|
        t.references :category, :event_type
      end
    end

    def self.down
      drop_table :categories_event_types
    end
end

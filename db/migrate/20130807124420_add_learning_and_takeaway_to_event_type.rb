# frozen_string_literal: true

class AddLearningAndTakeawayToEventType < ActiveRecord::Migration[4.2]
  def up
    add_column :event_types, :learnings, :text
    add_column :event_types, :takeaways, :text
  end

  def down
    remove_column :event_types, :learnings
    remove_column :event_types, :takeaways
  end
end

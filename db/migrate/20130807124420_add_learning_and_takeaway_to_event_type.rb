class AddLearningAndTakeawayToEventType < ActiveRecord::Migration
  def up
		add_column :event_types, :learnings, :text
		add_column :event_types, :takeaways, :text
	end
	
	def down
		remove_column :event_types, :learnings
		remove_column :event_types, :takeaways
	end
end

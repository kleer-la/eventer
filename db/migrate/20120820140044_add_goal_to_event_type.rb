class AddGoalToEventType < ActiveRecord::Migration
  def up
		add_column :event_types, :goal, :text
	end
	
	def down
		remove_column :event_types, :goal
	end
end

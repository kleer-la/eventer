class AddDurationToEventType < ActiveRecord::Migration
  def up
		add_column :event_types, :duration, :integer
	end
	
	def down
		remove_column :event_types, :duration
	end
end

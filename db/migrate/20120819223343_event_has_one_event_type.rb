class EventHasOneEventType < ActiveRecord::Migration
  def up
		add_column :events, :event_type_id, :integer
  end

	def down
		remove_column :events, :event_type_id
	end
end

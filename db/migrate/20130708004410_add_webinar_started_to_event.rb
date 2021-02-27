class AddWebinarStartedToEvent < ActiveRecord::Migration[5.0]
  def up
		add_column :events, :webinar_started, :boolean, :default => false
	end
	
	def down
		remove_column :events, :webinar_started
	end
end

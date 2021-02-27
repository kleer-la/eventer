class AddIsWebinarToEvent < ActiveRecord::Migration
  def up
		add_column :events, :is_webinar, :boolean, :default => false
	end
	
	def down
		remove_column :events, :is_webinar
	end
end

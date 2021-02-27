class AddIsWebinarToEvent < ActiveRecord::Migration[5.0]
  def up
		add_column :events, :is_webinar, :boolean, :default => false
	end
	
	def down
		remove_column :events, :is_webinar
	end
end

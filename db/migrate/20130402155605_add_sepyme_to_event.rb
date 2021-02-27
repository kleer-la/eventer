class AddSepymeToEvent < ActiveRecord::Migration
  def up
		add_column :events, :sepyme_enabled, :boolean
	end
	
	def down
		remove_column :events, :sepyme_enabled
	end
end

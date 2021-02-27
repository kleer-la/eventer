class AddMaterialsToEventType < ActiveRecord::Migration
  def up
		add_column :event_types, :materials, :text
	end
	
	def down
		remove_column :event_types, :materials
	end
end

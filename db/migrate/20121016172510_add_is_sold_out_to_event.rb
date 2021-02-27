class AddIsSoldOutToEvent < ActiveRecord::Migration[5.0]
  def up
		add_column :events, :is_sold_out, :boolean
	end
	
	def down
		remove_column :events, :is_sold_out
	end
end

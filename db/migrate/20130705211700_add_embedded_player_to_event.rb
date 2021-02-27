class AddEmbeddedPlayerToEvent < ActiveRecord::Migration
  def up
		add_column :events, :embedded_player, :text
	end
	
	def down
		remove_column :events, :embedded_player
	end
end

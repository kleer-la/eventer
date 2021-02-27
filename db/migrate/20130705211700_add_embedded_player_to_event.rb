class AddEmbeddedPlayerToEvent < ActiveRecord::Migration[5.0]
  def up
		add_column :events, :embedded_player, :text
	end
	
	def down
		remove_column :events, :embedded_player
	end
end

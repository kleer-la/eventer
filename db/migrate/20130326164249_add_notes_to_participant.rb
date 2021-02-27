class AddNotesToParticipant < ActiveRecord::Migration
  def up
		add_column :participants, :notes, :text
	end
	
	def down
		remove_column :participants, :notes
	end
end

class AddStatusToParticipants < ActiveRecord::Migration
  def up
		add_column :participants, :status, :string
	end
	
	def down
		remove_column :participants, :status
	end
end

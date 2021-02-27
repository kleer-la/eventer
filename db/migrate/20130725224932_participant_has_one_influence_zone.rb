class ParticipantHasOneInfluenceZone < ActiveRecord::Migration[5.0]
  def up
		add_column :participants, :influence_zone_id, :integer
  end

	def down
		remove_column :participants, :influence_zone_id
	end
end

class ParticipantHasOneInfluenceZone < ActiveRecord::Migration
  def up
		add_column :participants, :influence_zone_id, :integer
  end

	def down
		remove_column :participants, :influence_zone_id
	end
end

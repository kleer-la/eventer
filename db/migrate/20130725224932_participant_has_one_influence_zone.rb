# frozen_string_literal: true

class ParticipantHasOneInfluenceZone < ActiveRecord::Migration[4.2]
  def up
    add_column :participants, :influence_zone_id, :integer
  end

  def down
    remove_column :participants, :influence_zone_id
  end
end

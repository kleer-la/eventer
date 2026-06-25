# frozen_string_literal: true

# Removes the NPS promoter_score from participants (#74 phase B). The
# satisfaction survey (event_rating/trainer_rating/trainer2_rating/testimony)
# is intentionally kept; only the NPS metric is dropped.
class RemovePromoterScoreFromParticipants < ActiveRecord::Migration[8.1]
  def up
    remove_column :participants, :promoter_score if column_exists?(:participants, :promoter_score)
  end

  def down
    add_column :participants, :promoter_score, :integer
  end
end

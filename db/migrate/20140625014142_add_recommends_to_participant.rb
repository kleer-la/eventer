class AddRecommendsToParticipant < ActiveRecord::Migration
  def change
  	add_column :participants, :promoter_score, :integer
  end
end

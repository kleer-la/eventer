class AddRecommendsToParticipant < ActiveRecord::Migration[5.0]
  def change
  	add_column :participants, :promoter_score, :integer
  end
end

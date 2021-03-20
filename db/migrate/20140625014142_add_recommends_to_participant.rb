class AddRecommendsToParticipant < ActiveRecord::Migration[4.2]
  def change
  	add_column :participants, :promoter_score, :integer
  end
end

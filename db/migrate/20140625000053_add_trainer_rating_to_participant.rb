class AddTrainerRatingToParticipant < ActiveRecord::Migration[5.0]
  def change
  	add_column :participants, :trainer_rating, :integer
  end
end

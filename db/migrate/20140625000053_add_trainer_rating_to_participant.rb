class AddTrainerRatingToParticipant < ActiveRecord::Migration
  def change
  	add_column :participants, :trainer_rating, :integer
  end
end

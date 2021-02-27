class AddTrainer2RatingToParticipant < ActiveRecord::Migration[5.0]
  def change
      add_column :participants, :trainer2_rating, :integer
    end
end

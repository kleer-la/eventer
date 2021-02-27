class AddTrainer2RatingToParticipant < ActiveRecord::Migration
  def change
      add_column :participants, :trainer2_rating, :integer
    end
end

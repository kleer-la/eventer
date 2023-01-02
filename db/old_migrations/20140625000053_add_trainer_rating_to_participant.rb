# frozen_string_literal: true

class AddTrainerRatingToParticipant < ActiveRecord::Migration[4.2]
  def change
    add_column :participants, :trainer_rating, :integer
  end
end

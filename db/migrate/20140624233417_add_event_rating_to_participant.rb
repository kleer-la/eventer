class AddEventRatingToParticipant < ActiveRecord::Migration[5.0]
  def change
  	add_column :participants, :event_rating, :integer
  end
end

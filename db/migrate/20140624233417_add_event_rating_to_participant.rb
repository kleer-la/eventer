class AddEventRatingToParticipant < ActiveRecord::Migration
  def change
  	add_column :participants, :event_rating, :integer
  end
end

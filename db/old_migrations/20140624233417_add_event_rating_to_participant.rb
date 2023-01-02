# frozen_string_literal: true

class AddEventRatingToParticipant < ActiveRecord::Migration[4.2]
  def change
    add_column :participants, :event_rating, :integer
  end
end

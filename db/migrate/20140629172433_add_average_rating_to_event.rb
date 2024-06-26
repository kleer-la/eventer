# frozen_string_literal: true

class AddAverageRatingToEvent < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :average_rating, :decimal, precision: 4, scale: 2
  end
end

# frozen_string_literal: true

class AddRatingAtributesToEventType < ActiveRecord::Migration[4.2]
  def change
    add_column :event_types, :average_rating, :decimal, precision: 4, scale: 2
    add_column :event_types, :net_promoter_score, :integer
    add_column :event_types, :surveyed_count, :integer
    add_column :event_types, :promoter_count, :integer
  end
end

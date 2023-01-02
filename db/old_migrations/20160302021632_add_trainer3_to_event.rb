# frozen_string_literal: true

class AddTrainer3ToEvent < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :trainer3_id, :integer, null: true
  end
end

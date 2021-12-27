# frozen_string_literal: true

class CreateRatings < ActiveRecord::Migration[4.2]
  def change
    create_table :ratings do |t|
      t.references :user

      t.integer :global_nps
      t.integer :global_nps_count

      t.decimal :global_trainer_rating, precision: 4, scale: 2
      t.integer :global_trainer_rating_count

      t.decimal :global_event_rating, precision: 4, scale: 2
      t.integer :global_event_rating_count

      t.timestamps null: true
    end
    add_index :ratings, :user_id
  end
end

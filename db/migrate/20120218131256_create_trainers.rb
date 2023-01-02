# frozen_string_literal: true

class CreateTrainers < ActiveRecord::Migration[4.2]
  def change
    create_table :trainers do |t|
      t.string :name

      t.timestamps null: true
    end
  end
end

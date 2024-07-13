# frozen_string_literal: true

class CreateServices < ActiveRecord::Migration[7.1]
  def change
    create_table :services do |t|
      t.string :name
      t.text :card_description
      t.string :subtitle
      t.references :service_area, foreign_key: true

      t.timestamps
    end
  end
end

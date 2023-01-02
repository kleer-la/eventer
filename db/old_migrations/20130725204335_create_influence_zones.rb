# frozen_string_literal: true

class CreateInfluenceZones < ActiveRecord::Migration[4.2]
  def change
    create_table :influence_zones do |t|
      t.string :zone_name
      t.string :tag_name
      t.references :country

      t.timestamps null: true
    end
  end
end

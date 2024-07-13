# frozen_string_literal: true

class CreateLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :logs do |t|
      t.integer :area
      t.integer :level
      t.string :message
      t.text :details

      t.timestamps
    end
  end
end

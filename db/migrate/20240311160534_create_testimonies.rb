# frozen_string_literal: true

class CreateTestimonies < ActiveRecord::Migration[7.1]
  def change
    create_table :testimonies do |t|
      t.string :first_name
      t.string :last_name
      t.string :profile_url
      t.string :photo_url
      t.references :service, foreign_key: true
      t.boolean :stared

      t.timestamps
    end
  end
end

# frozen_string_literal: true

class AddEnBioToTrainer < ActiveRecord::Migration[4.2]
  def up
    add_column :trainers, :bio_en, :text
  end

  def down
    remove_column :trainers, :bio_en
  end
end

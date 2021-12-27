# frozen_string_literal: true

class AddBioToTrainer < ActiveRecord::Migration[4.2]
  def up
    add_column :trainers, :bio, :text
  end

  def down
    remove_column :trainers, :bio
  end
end

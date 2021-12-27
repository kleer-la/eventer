# frozen_string_literal: true

class AddIsKleererToTrainer < ActiveRecord::Migration[4.2]
  def up
    add_column :trainers, :is_kleerer, :boolean
  end

  def down
    remove_column :trainers, :is_kleerer
  end
end

# frozen_string_literal: true

class AddDeletedToTrainers < ActiveRecord::Migration[5.2]
  def change
    add_column :trainers, :deleted, :boolean, default: false
  end
end

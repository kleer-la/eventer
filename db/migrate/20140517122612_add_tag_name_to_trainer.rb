# frozen_string_literal: true

class AddTagNameToTrainer < ActiveRecord::Migration[4.2]
  def change
    add_column :trainers, :tag_name, :string
  end
end

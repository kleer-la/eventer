# frozen_string_literal: true

class AddTaglineToCategory < ActiveRecord::Migration[4.2]
  def up
    add_column :categories, :tagline, :string
  end

  def down
    remove_column :categories, :tagline
  end
end

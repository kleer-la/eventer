# frozen_string_literal: true

class AddVisibilityAndOrderToCategory < ActiveRecord::Migration[4.2]
  def up
    add_column :categories, :visible, :boolean
    add_column :categories, :order, :integer, default: 0
  end

  def down
    remove_column :categories, :visible
    remove_column :categories, :order
  end
end

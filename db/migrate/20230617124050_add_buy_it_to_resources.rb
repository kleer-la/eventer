# frozen_string_literal: true

class AddBuyItToResources < ActiveRecord::Migration[7.0]
  def change
    add_column :resources, :buyit_es, :string
    add_column :resources, :buyit_en, :string
  end
end

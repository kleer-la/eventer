# frozen_string_literal: true

class AddSlugToServiceAreas < ActiveRecord::Migration[7.1]
  def change
    add_column :service_areas, :slug, :string
    add_index :service_areas, :slug, unique: true
  end
end

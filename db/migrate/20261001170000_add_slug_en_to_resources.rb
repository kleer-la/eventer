# frozen_string_literal: true

# A resource's own English slug, for /en/resources/<slug_en> (#227).
class AddSlugEnToResources < ActiveRecord::Migration[8.1]
  def change
    add_column :resources, :slug_en, :string
    add_index :resources, :slug_en, unique: true
  end
end

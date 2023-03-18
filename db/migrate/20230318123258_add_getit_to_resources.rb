class AddGetitToResources < ActiveRecord::Migration[6.1]
  def change
    add_column :resources, :downloadable, :boolean
    add_column :resources, :getit_es, :string
    add_column :resources, :getit_en, :string
  end
end

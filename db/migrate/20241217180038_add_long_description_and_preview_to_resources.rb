class AddLongDescriptionAndPreviewToResources < ActiveRecord::Migration[7.1]
  def change
    add_column :resources, :long_description_es, :text
    add_column :resources, :long_description_en, :text
    add_column :resources, :preview_es, :string
    add_column :resources, :preview_en, :string
  end
end

class AddFieldsToServiceAreas < ActiveRecord::Migration[7.1]
  def change
    add_column :service_areas, :icon, :string
    add_column :service_areas, :primary_color, :string
    add_column :service_areas, :secondary_color, :string
  end
end

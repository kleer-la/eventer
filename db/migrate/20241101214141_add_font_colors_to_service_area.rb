class AddFontColorsToServiceArea < ActiveRecord::Migration[7.1]
  def change
    add_column :service_areas, :primary_font_color, :string, default: '#000000'
    add_column :service_areas, :secondary_font_color, :string, default: '#000000'
  end
end

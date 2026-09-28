# frozen_string_literal: true

# The picture beside the hero text of an area or service page. Empty keeps the
# hero in a single column.
class AddHeroImageToServiceAreasAndServices < ActiveRecord::Migration[8.1]
  def change
    add_column :service_areas, :hero_image, :string
    add_column :services, :hero_image, :string
  end
end

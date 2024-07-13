# frozen_string_literal: true

class AddTargetTitleToServiceAreas < ActiveRecord::Migration[7.1]
  def change
    add_column :service_areas, :target_title, :string
  end
end

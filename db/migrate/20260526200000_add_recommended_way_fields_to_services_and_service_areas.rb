# frozen_string_literal: true

class AddRecommendedWayFieldsToServicesAndServiceAreas < ActiveRecord::Migration[7.2]
  def change
    add_column :services, :recommended_way_title, :string
    add_column :services, :recommended_way_note, :string
    add_column :services, :recommended_way_summary, :text
    add_column :services, :recommended_way_details, :text

    add_column :service_areas, :recommended_way_title, :string
    add_column :service_areas, :recommended_way_note, :string
    add_column :service_areas, :recommended_way_summary, :text
    add_column :service_areas, :recommended_way_details, :text
  end
end

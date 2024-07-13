# frozen_string_literal: true

class AddSeoToServiceAreas < ActiveRecord::Migration[7.1]
  def change
    add_column :service_areas, :seo_title, :string
    add_column :service_areas, :seo_description, :string
  end
end

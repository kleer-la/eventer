# frozen_string_literal: true

class AddVisibleAndLangToServiceAreas < ActiveRecord::Migration[7.1]
  def change
    add_column :service_areas, :visible, :boolean
    add_column :service_areas, :lang, :integer
    ServiceArea.where(lang: nil).update_all(lang: 0)
  end
end

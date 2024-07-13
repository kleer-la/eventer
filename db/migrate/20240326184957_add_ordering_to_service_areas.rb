# frozen_string_literal: true

class AddOrderingToServiceAreas < ActiveRecord::Migration[7.1]
  def change
    add_column :service_areas, :ordering, :integer
  end
end

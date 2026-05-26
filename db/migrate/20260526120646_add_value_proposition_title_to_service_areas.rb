# frozen_string_literal: true

class AddValuePropositionTitleToServiceAreas < ActiveRecord::Migration[7.2]
  def change
    add_column :service_areas, :value_proposition_title, :string
  end
end

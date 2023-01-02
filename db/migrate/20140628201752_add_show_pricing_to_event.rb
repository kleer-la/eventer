# frozen_string_literal: true

class AddShowPricingToEvent < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :show_pricing, :boolean, default: false
  end
end

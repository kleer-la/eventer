class AddShowPricingToEvent < ActiveRecord::Migration[5.0]
  def change
  	add_column :events, :show_pricing, :boolean, :default => false
  end
end

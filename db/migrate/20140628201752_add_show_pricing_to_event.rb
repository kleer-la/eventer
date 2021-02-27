class AddShowPricingToEvent < ActiveRecord::Migration
  def change
  	add_column :events, :show_pricing, :boolean, :default => false
  end
end

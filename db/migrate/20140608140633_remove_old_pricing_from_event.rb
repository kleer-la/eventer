class RemoveOldPricingFromEvent < ActiveRecord::Migration
  def up
  	remove_column :events, :list_price_plus_tax
  	remove_column :events, :list_price_2_pax_discount
  	remove_column :events, :list_price_3plus_pax_discount
  end

  def down
  	add_column :events, :list_price_plus_tax, :boolean
  	add_column :events, :list_price_2_pax_discount, :integer
  	add_column :events, :list_price_3plus_pax_discount, :integer
  end
end

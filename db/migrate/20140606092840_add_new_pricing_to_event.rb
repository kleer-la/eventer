class AddNewPricingToEvent < ActiveRecord::Migration[4.2]
  def change
  	add_column :events, :couples_eb_price, :decimal, :precision => 10, :scale => 2
  	add_column :events, :business_price, :decimal, :precision => 10, :scale => 2
  	add_column :events, :business_eb_price, :decimal, :precision => 10, :scale => 2
  	add_column :events, :enterprise_6plus_price, :decimal, :precision => 10, :scale => 2
  	add_column :events, :enterprise_11plus_price, :decimal, :precision => 10, :scale => 2
  end
end

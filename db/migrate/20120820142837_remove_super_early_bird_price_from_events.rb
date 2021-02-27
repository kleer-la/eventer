class RemoveSuperEarlyBirdPriceFromEvents < ActiveRecord::Migration[5.0]
  def up
  	remove_column :events, :seb_price
  	remove_column :events, :seb_end_date
  end

  def down
    add_column :events, :seb_price, :decimal, :precision => 7, :scale => 2
    add_column :events, :seb_end_date, :date
  end
end

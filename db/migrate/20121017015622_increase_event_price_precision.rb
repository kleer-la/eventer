class IncreaseEventPricePrecision < ActiveRecord::Migration[4.2]
  def up
    change_column :events, :list_price, :decimal, :precision => 10, :scale => 2
    change_column :events, :eb_price, :decimal, :precision => 10, :scale => 2
  end

  def down
    change_column :events, :list_price, :decimal, :precision => 7, :scale => 2
    change_column :events, :eb_price, :decimal, :precision => 7, :scale => 2
  end
end

class AddCurrencyToEvent < ActiveRecord::Migration
  def up
		add_column :events, :currency_iso_code, :string
	end
	
	def down
		remove_column :events, :currency_iso_code
	end
end

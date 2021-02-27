class AddAddressToEvent < ActiveRecord::Migration[5.0]
  def up
		add_column :events, :address, :string
	end
	
	def down
		remove_column :events, :address
	end
end

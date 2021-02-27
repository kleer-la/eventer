class AddIsKleererToTrainer < ActiveRecord::Migration
  def up
		add_column :trainers, :is_kleerer, :boolean
	end
	
	def down
		remove_column :trainers, :is_kleerer
	end
end

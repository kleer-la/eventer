class AddTaglineToCategory < ActiveRecord::Migration
  def up
		add_column :categories, :tagline, :string
	end
	
	def down
		remove_column :categories, :tagline
	end
end

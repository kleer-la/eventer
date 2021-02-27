class AddLinkedInUrlToTrainer < ActiveRecord::Migration
  def up
		add_column :trainers, :linkedin_url, :string
	end
	
	def down
		remove_column :trainers, :linkedin_url
	end
end

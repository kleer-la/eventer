class AddTwitterUsernameToTrainer < ActiveRecord::Migration
  def up
		add_column :trainers, :twitter_username, :string
	end
	
	def down
		remove_column :trainers, :twitter_username
	end
end

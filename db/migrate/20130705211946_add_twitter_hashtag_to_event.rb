class AddTwitterHashtagToEvent < ActiveRecord::Migration[5.0]
  def up
		add_column :events, :twitter_hashtag, :string
	end
	
	def down
		remove_column :events, :twitter_hashtag
	end
end

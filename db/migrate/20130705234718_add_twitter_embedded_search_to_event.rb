class AddTwitterEmbeddedSearchToEvent < ActiveRecord::Migration[4.2]
  def up
		add_column :events, :twitter_embedded_search, :text
		remove_column :events, :twitter_hashtag
	end
	
	def down
		remove_column :events, :twitter_embedded_search
		add_column :events, :twitter_hashtag, :string
	end
end

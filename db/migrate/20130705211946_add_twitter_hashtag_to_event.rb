# frozen_string_literal: true

class AddTwitterHashtagToEvent < ActiveRecord::Migration[4.2]
  def up
    add_column :events, :twitter_hashtag, :string
  end

  def down
    remove_column :events, :twitter_hashtag
  end
end

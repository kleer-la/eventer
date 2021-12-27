# frozen_string_literal: true

class AddTwitterUsernameToTrainer < ActiveRecord::Migration[4.2]
  def up
    add_column :trainers, :twitter_username, :string
  end

  def down
    remove_column :trainers, :twitter_username
  end
end

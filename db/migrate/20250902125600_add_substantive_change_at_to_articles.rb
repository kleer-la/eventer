# frozen_string_literal: true

class AddSubstantiveChangeAtToArticles < ActiveRecord::Migration[7.2]
  def up
    add_column :articles, :substantive_change_at, :datetime
    add_index :articles, :substantive_change_at

    # Set substantive_change_at = created_at for existing records
    Article.update_all('substantive_change_at = created_at')
  end

  def down
    remove_index :articles, :substantive_change_at
    remove_column :articles, :substantive_change_at
  end
end

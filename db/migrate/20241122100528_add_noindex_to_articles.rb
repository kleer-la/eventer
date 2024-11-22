class AddNoindexToArticles < ActiveRecord::Migration[7.1]
  def change
    add_column :articles, :noindex, :boolean, default: false, null: false
  end
end

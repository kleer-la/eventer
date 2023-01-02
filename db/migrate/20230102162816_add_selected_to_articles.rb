class AddSelectedToArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :articles, :cover, :string
    add_column :articles, :selected, :boolean, null: false, default: false
  end
end

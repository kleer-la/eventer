class AddHeaderToArticles < ActiveRecord::Migration[7.2]
  def change
    add_column :articles, :header, :string
  end
end

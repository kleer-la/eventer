class AddIndustryToArticles < ActiveRecord::Migration[7.1]
  def change
    add_column :articles, :industry, :integer
  end
end

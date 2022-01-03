# frozen_string_literal: true

class AddCategoryToArticles < ActiveRecord::Migration[5.2]
  def change
    add_reference :articles, :category, foreign_key: true
  end
end

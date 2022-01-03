# frozen_string_literal: true

class AddLangToArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :articles, :lang, :integer, null: false, default: 0
  end
end

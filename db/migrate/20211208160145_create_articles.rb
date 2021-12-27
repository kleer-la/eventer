# frozen_string_literal: true

class CreateArticles < ActiveRecord::Migration[5.2]
  def change
    create_table :articles do |t|
      t.string :title, null: false
      t.text :body
      t.boolean :published, default: false
      t.string :slug, null: false
      t.string :description
      t.string :tabtitle

      t.timestamps
    end
    add_index :articles, :slug, unique: true
  end
end

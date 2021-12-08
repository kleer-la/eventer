class CreateArticles < ActiveRecord::Migration[5.2]
  def change
    create_table :articles do |t|
      t.string :title
      t.text :body
      t.boolean :published, default: false
      t.string :slug, null: false
      t.string :description

      t.timestamps
    end
  end
end

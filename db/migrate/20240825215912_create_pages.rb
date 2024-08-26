class CreatePages < ActiveRecord::Migration[7.1]
  def change
    create_table :pages do |t|
      t.string :name
      t.string :slug
      t.string :seo_title
      t.text :seo_description
      t.integer :lang
      t.string :canonical

      t.timestamps
    end
    add_index :pages, %i[slug lang], unique: true
  end
end

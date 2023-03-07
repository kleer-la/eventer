class CreateResources < ActiveRecord::Migration[6.1]
  def change
    create_table :resources do |t|
      # t.string :id
      t.integer :format
      t.references :categories, foreign_key: true
      t.references :trainers, foreign_key: true
      t.string :slug, null: false

      t.string :landing_es
      t.string :cover_es
      t.string :title_es
      t.text :description_es
      t.string :share_link_es
      t.string :share_text_es
      t.string :tags_es
      t.text :comments_es

      t.string :landing_en
      t.string :cover_en
      t.string :title_en
      t.text :description_en
      t.string :share_link_en
      t.string :share_text_en
      t.string :tags_en
      t.text :comments_en

      t.timestamps
    end
    add_index :resources, :slug, unique: true
  end
end
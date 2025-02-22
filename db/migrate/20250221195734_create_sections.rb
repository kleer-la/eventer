class CreateSections < ActiveRecord::Migration[7.1]
  def change
    create_table :sections do |t|
      t.references :page, foreign_key: true
      t.string :title
      t.text :content
      t.integer :position
      t.string :slug

      t.timestamps
    end
    add_index :sections, %i[slug page_id], unique: true
  end
end

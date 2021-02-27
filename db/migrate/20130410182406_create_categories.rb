class CreateCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :categories do |t|
      t.string :name
      t.text :description
      t.string :codename

      t.timestamps null: true
    end
  end
end

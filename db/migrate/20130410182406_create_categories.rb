class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.string :name
      t.text :description
      t.string :codename

      t.timestamps null: true
    end
  end
end

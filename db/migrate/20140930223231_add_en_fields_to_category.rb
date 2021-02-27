class AddEnFieldsToCategory < ActiveRecord::Migration
  def up
    add_column :categories, :name_en, :string
    add_column :categories, :description_en, :string
    add_column :categories, :tagline_en, :string
  end

  def down
    remove_column :categories, :name_en
    remove_column :categories, :description_en
    remove_column :categories, :tagline_en
  end
end

class ChangeCategoryDecriptionEnToText < ActiveRecord::Migration
  def change
    change_column :categories, :description_en, :text
  end
end

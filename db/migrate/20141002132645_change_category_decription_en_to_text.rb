class ChangeCategoryDecriptionEnToText < ActiveRecord::Migration[5.0]
  def change
    change_column :categories, :description_en, :text
  end
end

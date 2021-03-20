class ChangeCategoryDecriptionEnToText < ActiveRecord::Migration[4.2]
  def change
    change_column :categories, :description_en, :text
  end
end

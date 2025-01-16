class RemoveTrainersIdAndRenameCategoriesId < ActiveRecord::Migration[7.1]
  def change
    remove_column :resources, :trainers_id
    rename_column :resources, :categories_id, :category_id
  end
end

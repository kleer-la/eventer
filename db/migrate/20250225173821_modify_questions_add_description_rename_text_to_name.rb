class ModifyQuestionsAddDescriptionRenameTextToName < ActiveRecord::Migration[7.0]
  def change
    rename_column :questions, :text, :name
    add_column :questions, :description, :text
  end
end

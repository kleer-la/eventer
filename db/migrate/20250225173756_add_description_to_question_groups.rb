class AddDescriptionToQuestionGroups < ActiveRecord::Migration[7.1]
  def change
    add_column :question_groups, :description, :text
  end
end

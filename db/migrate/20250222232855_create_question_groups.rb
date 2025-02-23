class CreateQuestionGroups < ActiveRecord::Migration[7.1]
  def change
    create_table :question_groups do |t|
      t.references :assessment, null: false, foreign_key: true
      t.string :name
      t.integer :position

      t.timestamps
    end
  end
end

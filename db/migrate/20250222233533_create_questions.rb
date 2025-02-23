class CreateQuestions < ActiveRecord::Migration[7.1]
  def change
    create_table :questions do |t|
      t.references :assessment, null: false, foreign_key: true
      t.references :question_group, null: true, foreign_key: true
      t.string :text
      t.integer :position
      t.string :question_type, default: 'linear_scale'

      t.timestamps
    end
  end
end

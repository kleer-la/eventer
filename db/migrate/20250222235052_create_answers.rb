class CreateAnswers < ActiveRecord::Migration[7.1]
  def change
    create_table :answers do |t|
      t.references :question, null: false, foreign_key: true
      t.string :text
      t.integer :position

      t.timestamps
    end
  end
end

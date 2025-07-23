class CreateRules < ActiveRecord::Migration[7.2]
  def change
    create_table :rules do |t|
      t.references :assessment, null: false, foreign_key: true
      t.integer :position, null: false
      t.text :conditions, default: '{}', null: false
      t.text :diagnostic_text, null: false

      t.timestamps
    end

    add_index :rules, %i[assessment_id position], unique: true
  end
end

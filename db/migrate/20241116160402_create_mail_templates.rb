class CreateMailTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :mail_templates do |t|
      t.integer :trigger_type, null: false
      t.string :identifier, null: false
      t.string :subject, null: false
      t.text :content, null: false
      t.integer :delivery_schedule, default: 0
      t.string :to, null: false
      t.string :cc
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :mail_templates, :trigger_type
    add_index :mail_templates, :identifier, unique: true
    add_index :mail_templates, :delivery_schedule
  end
end

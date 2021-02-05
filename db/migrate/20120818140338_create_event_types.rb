class CreateEventTypes < ActiveRecord::Migration
  def change
    create_table :event_types do |t|
      t.string :name
      t.text :description
      t.text :recipients
      t.text :program

      t.timestamps null: true
    end
  end
end

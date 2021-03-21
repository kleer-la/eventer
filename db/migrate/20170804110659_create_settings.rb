class CreateSettings < ActiveRecord::Migration[4.2]
  def change
    create_table :settings do |t|
      t.string :key
      t.text :value

      t.timestamps null: true
    end
  end
end

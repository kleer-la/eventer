class CreateCountries < ActiveRecord::Migration[4.2]
  def change
    create_table :countries do |t|
      t.string :name
      t.string :iso_code

      t.timestamps null: true
    end
  end
end

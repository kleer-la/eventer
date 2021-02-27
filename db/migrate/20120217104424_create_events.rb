class CreateEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :events do |t|
      t.string :name
      t.date :date
      t.string :place
      t.integer :capacity
      t.string :city
      t.references :country
      t.references :trainer
      t.string :visibility_type, :limit => 2
      t.decimal :list_price, :precision => 7, :scale => 2
      t.boolean :list_price_plus_tax
      t.integer :list_price_2_pax_discount
      t.integer :list_price_3plus_pax_discount
      t.decimal :seb_price, :precision => 7, :scale => 2
      t.date :seb_end_date
      t.decimal :eb_price, :precision => 7, :scale => 2
      t.date :eb_end_date
      t.text :description
      t.text :recipients
      t.text :program
      t.boolean :draft
      t.boolean :cancelled

      t.timestamps null: true
    end
    add_index :events, :country_id
    add_index :events, :trainer_id
  end
end

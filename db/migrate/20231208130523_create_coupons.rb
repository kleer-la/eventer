class CreateCoupons < ActiveRecord::Migration[7.1]
  def change
    create_table :coupons do |t|
      t.integer :coupon_type
      t.string :code
      t.string :internal_name
      t.string :icon
      t.date :expires_on
      t.boolean :display
      t.boolean :active
      t.decimal :percent_off, precision: 5, scale: 2
      t.decimal :amount_off, precision: 10, scale: 2

      t.timestamps
    end
  end
end

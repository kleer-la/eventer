class AddJitPaymentUrlToEvent < ActiveRecord::Migration
  def change
    add_column :events, :jit_payment_link, :string
  end
end

class AddPaymentTypeAndFlagToParticipant < ActiveRecord::Migration[5.0]
  def change
    add_column :participants, :is_payed, :boolean, default: false
    add_column :participants, :payment_type, :string
  end
end

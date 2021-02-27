class AddXeroFieldsToParticipant < ActiveRecord::Migration
  def change
    add_column :participants, :xero_invoice_number, :string, null: true
    add_column :participants, :xero_invoice_reference, :string, null: true
    add_column :participants, :xero_invoice_amount, :decimal, :precision => 10, :scale => 2
  end
end

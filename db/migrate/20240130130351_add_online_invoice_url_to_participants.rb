class AddOnlineInvoiceUrlToParticipants < ActiveRecord::Migration[7.1]
  def change
    add_column :participants, :online_invoice_url, :string
  end
end

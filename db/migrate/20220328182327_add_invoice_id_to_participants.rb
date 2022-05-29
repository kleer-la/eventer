# frozen_string_literal: true

class AddInvoiceIdToParticipants < ActiveRecord::Migration[5.2]
  def change
    add_column :participants, :invoice_id, :string
  end
end

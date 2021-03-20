class AddKonlinePoNumberToParticipant < ActiveRecord::Migration[4.2]
  def change
    add_column :participants, :konline_po_number, :string
  end
end

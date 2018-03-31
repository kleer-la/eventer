class AddKonlinePoNumberToParticipant < ActiveRecord::Migration
  def change
    add_column :participants, :konline_po_number, :string
  end
end

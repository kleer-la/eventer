class AddPayNotes < ActiveRecord::Migration[5.0]
  def change
    add_column :participants, :pay_notes, :string
  end
end

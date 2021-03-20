class AddPayNotes < ActiveRecord::Migration[4.2]
  def change
    add_column :participants, :pay_notes, :string
  end
end

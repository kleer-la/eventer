class AddPayNotes < ActiveRecord::Migration
  def change
    add_column :participants, :pay_notes, :string
  end
end

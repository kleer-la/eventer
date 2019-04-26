class ChangePayNotes < ActiveRecord::Migration
  def change
    add_column :participants, :pay_notes, :string
    change_column :participants, :pay_notes, :text
  end
end

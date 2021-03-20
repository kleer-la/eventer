class ChangePayNotes < ActiveRecord::Migration[4.2]
  def change
    change_column :participants, :pay_notes, :text
  end
end

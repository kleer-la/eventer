class ChangePayNotes < ActiveRecord::Migration
  def change
    change_column :participants, :pay_notes, :text
  end
end

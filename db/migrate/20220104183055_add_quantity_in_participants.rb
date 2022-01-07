class AddQuantityInParticipants < ActiveRecord::Migration[5.2]
  def change
    add_column :participants, :quantity, :integer, null: false, default: 1
  end
end

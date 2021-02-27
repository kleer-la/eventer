class Add2ndTrainerRefEvent < ActiveRecord::Migration[5.0]
  def up
    add_column :events, :trainer2_id, :integer, null: true
  end

  def down
    remove_column :events, :trainer2_id
  end
end

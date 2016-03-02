class AddTrainer3ToEvent < ActiveRecord::Migration
  def change
    add_column :events, :trainer3_id, :integer, null: true
  end
end

class AddTrainer3ToEvent < ActiveRecord::Migration[5.0]
  def change
    add_column :events, :trainer3_id, :integer, null: true
  end
end

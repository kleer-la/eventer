class AddDeletedToTrainers < ActiveRecord::Migration[5.2]
  def change
    add_column :trainers, :deleted, :bool, default: false
  end
end

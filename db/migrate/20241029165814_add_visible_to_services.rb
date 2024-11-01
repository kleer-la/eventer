class AddVisibleToServices < ActiveRecord::Migration[7.1]
  def change
    add_column :services, :visible, :boolean, default: false, null: false
  end
end

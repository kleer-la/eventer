class AddVisibleToNews < ActiveRecord::Migration[7.2]
  def change
    add_column :news, :visible, :boolean, default: true, null: false
  end
end

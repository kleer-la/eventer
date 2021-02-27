class AddModeToEvent < ActiveRecord::Migration[5.0]
  def change
  	add_column :events, :mode, :string, :limit => 2
  end
end

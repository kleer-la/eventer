class AddModeToEvent < ActiveRecord::Migration
  def change
  	add_column :events, :mode, :string, :limit => 2
  end
end

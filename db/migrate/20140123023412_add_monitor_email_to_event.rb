class AddMonitorEmailToEvent < ActiveRecord::Migration
  def change
    add_column :events, :monitor_email, :string
  end
end

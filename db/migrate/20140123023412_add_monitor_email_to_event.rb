# frozen_string_literal: true

class AddMonitorEmailToEvent < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :monitor_email, :string
  end
end

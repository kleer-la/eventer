# frozen_string_literal: true

class AddTimeZoneNameToEvent < ActiveRecord::Migration[4.2]
  def up
    add_column :events, :time_zone_name, :string
  end

  def down
    remove_column :events, :time_zone_name
  end
end

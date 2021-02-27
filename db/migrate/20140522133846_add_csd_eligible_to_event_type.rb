class AddCsdEligibleToEventType < ActiveRecord::Migration
  def change
  	add_column :event_types, :csd_eligible, :boolean
  end
end

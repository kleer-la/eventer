# frozen_string_literal: true

class AddCsdEligibleToEventType < ActiveRecord::Migration[4.2]
  def change
    add_column :event_types, :csd_eligible, :boolean
  end
end

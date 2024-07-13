# frozen_string_literal: true

class AddPlatformAndExternalIdToEventTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :event_types, :platform, :integer, default: 0
    add_column :event_types, :external_id, :integer
  end
end

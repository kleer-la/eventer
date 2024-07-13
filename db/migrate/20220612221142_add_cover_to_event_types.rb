# frozen_string_literal: true

class AddCoverToEventTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :event_types, :cover, :string
  end
end

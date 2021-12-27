# frozen_string_literal: true

class AddSubtitleEventType < ActiveRecord::Migration[4.2]
  def change
    add_column :event_types, :subtitle, :string
  end
end

# frozen_string_literal: true

class AddOrderingToEventTypes < ActiveRecord::Migration[7.2]
  def change
    add_column :event_types, :ordering, :integer, default: 100

    reversible do |dir|
      dir.up do
        EventType.update_all(ordering: 100)
      end
    end
  end
end

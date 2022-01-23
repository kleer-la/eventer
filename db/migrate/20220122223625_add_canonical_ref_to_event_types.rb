# frozen_string_literal: true

class AddCanonicalRefToEventTypes < ActiveRecord::Migration[5.2]
  def change
    add_reference :event_types, :canonical, references: :event_types, foreign_key: { to_table: :event_types }
  end
end

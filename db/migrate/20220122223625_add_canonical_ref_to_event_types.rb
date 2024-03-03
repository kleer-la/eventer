# frozen_string_literal: true

class AddCanonicalRefToEventTypes < ActiveRecord::Migration[6.0]
  def change
    add_reference :event_types, :canonical, foreign_key: { to_table: :event_types }
  end
end

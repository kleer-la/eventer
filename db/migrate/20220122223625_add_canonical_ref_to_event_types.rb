# frozen_string_literal: true

class AddCanonicalRefToEventTypes < ActiveRecord::Migration[5.2]
  def change
    add_reference :event_types, :canonical, references: :event_types, foreign_key: true, index: true
  end
end

# frozen_string_literal: true

class AddLangToEventTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :event_types, :lang, :integer, null: false, default: 0
  end
end

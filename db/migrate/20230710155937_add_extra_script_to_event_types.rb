# frozen_string_literal: true

class AddExtraScriptToEventTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :event_types, :extra_script, :text
  end
end

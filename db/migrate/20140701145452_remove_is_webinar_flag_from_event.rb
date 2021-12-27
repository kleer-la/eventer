# frozen_string_literal: true

class RemoveIsWebinarFlagFromEvent < ActiveRecord::Migration[4.2]
  def up
    remove_column :events, :is_webinar
  end

  def down
    add_column :events, :is_webinar, :boolean
  end
end

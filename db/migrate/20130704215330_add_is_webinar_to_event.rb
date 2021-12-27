# frozen_string_literal: true

class AddIsWebinarToEvent < ActiveRecord::Migration[4.2]
  def up
    add_column :events, :is_webinar, :boolean, default: false
  end

  def down
    remove_column :events, :is_webinar
  end
end

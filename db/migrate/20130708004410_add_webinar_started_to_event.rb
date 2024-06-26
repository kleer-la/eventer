# frozen_string_literal: true

class AddWebinarStartedToEvent < ActiveRecord::Migration[4.2]
  def up
    add_column :events, :webinar_started, :boolean, default: false
  end

  def down
    remove_column :events, :webinar_started
  end
end

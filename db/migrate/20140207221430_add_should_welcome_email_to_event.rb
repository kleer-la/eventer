# frozen_string_literal: true

class AddShouldWelcomeEmailToEvent < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :should_welcome_email, :boolean, default: true
  end
end

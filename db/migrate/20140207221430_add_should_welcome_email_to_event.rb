class AddShouldWelcomeEmailToEvent < ActiveRecord::Migration
  def change
    add_column :events, :should_welcome_email, :boolean, default: true
  end
end

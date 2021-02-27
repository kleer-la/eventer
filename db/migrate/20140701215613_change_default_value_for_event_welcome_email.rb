class ChangeDefaultValueForEventWelcomeEmail < ActiveRecord::Migration
  def up
  	change_column :events, :should_welcome_email, :boolean, :default => true
  end

  def down
  	change_column :events, :should_welcome_email, :boolean, :default => nil
  end
end

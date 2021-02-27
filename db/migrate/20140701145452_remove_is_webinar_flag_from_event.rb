class RemoveIsWebinarFlagFromEvent < ActiveRecord::Migration
  def up
  	remove_column :events, :is_webinar
  end

  def down
  	add_column :events, :is_webinar, :boolean
  end
end

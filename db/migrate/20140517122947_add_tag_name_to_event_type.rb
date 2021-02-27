class AddTagNameToEventType < ActiveRecord::Migration
  def change
  	add_column :event_types, :tag_name, :string
  end
end

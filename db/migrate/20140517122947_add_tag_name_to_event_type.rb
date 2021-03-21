class AddTagNameToEventType < ActiveRecord::Migration[4.2]
  def change
  	add_column :event_types, :tag_name, :string
  end
end

class AddTagNameToEventType < ActiveRecord::Migration[5.0]
  def change
  	add_column :event_types, :tag_name, :string
  end
end

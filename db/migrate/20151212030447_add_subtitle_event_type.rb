class AddSubtitleEventType < ActiveRecord::Migration
  def change
    add_column :event_types, :subtitle, :string
  end
end

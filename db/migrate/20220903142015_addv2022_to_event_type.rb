class Addv2022ToEventType < ActiveRecord::Migration[5.2]
  def change
    add_column :event_types, :side_image, :string
    add_column :event_types, :brochure, :string
    add_column :event_types, :new_version, :boolean, null: false, default: false
  end
end

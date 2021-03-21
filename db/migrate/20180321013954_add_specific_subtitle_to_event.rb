class AddSpecificSubtitleToEvent < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :specific_subtitle, :string
  end
end

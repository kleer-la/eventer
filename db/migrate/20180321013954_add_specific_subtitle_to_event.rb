class AddSpecificSubtitleToEvent < ActiveRecord::Migration[5.0]
  def change
    add_column :events, :specific_subtitle, :string
  end
end

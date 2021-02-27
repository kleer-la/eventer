class AddSpecificSubtitleToEvent < ActiveRecord::Migration
  def change
    add_column :events, :specific_subtitle, :string
  end
end

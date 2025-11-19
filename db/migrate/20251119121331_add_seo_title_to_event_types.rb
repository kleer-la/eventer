class AddSeoTitleToEventTypes < ActiveRecord::Migration[7.2]
  def change
    add_column :event_types, :seo_title, :string
  end
end

class AddExternalSiteForEventType < ActiveRecord::Migration[5.0]
  def change
    add_column :event_types, :external_site_url, :string
  end
end

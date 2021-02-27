class AddExternalSiteForEventType < ActiveRecord::Migration
  def change
    add_column :event_types, :external_site_url, :string
  end
end

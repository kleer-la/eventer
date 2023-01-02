# frozen_string_literal: true

class AddExternalSiteForEventType < ActiveRecord::Migration[4.2]
  def change
    add_column :event_types, :external_site_url, :string
  end
end

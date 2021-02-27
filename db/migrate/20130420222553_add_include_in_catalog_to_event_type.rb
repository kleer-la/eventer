class AddIncludeInCatalogToEventType < ActiveRecord::Migration
  def up
		add_column :event_types, :include_in_catalog, :boolean
	end
	
	def down
		remove_column :event_types, :include_in_catalog
	end
end

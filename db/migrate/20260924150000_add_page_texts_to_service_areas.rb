# frozen_string_literal: true

# The hero and contact texts of an area page come from one Page shared by every
# area. These let an area bring its own; empty means "use the shared one".
class AddPageTextsToServiceAreas < ActiveRecord::Migration[7.2]
  def change
    add_column :service_areas, :hero_cta_text, :string
    add_column :service_areas, :hero_secondary_cta_text, :string
    add_column :service_areas, :hero_secondary_cta_target, :string
    add_column :service_areas, :hero_note, :string
    add_column :service_areas, :contact_title, :string
    add_column :service_areas, :contact_cta_text, :string
  end
end

# frozen_string_literal: true

# The contact block of an area page closes with a title and the promise that
# backs it; contact_title held the first, this holds the second. Empty keeps
# the shared text of the "service-area" Page.
class AddContactTextToServiceAreas < ActiveRecord::Migration[7.2]
  def change
    add_column :service_areas, :contact_text, :text
  end
end

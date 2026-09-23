# frozen_string_literal: true

# An area can be an offering in itself: it gets the two plain columns a
# Service has for that (the rich-text blocks live in action_text_rich_texts).
class AddOfferingFieldsToServiceAreas < ActiveRecord::Migration[7.2]
  def change
    add_column :service_areas, :pricing, :string
    add_column :service_areas, :brochure, :string
  end
end

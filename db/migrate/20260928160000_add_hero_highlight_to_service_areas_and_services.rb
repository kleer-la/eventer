# frozen_string_literal: true

# A fact shown over the hero picture: a big figure ("2 semanas") and the line
# under it. Empty shows the picture alone.
class AddHeroHighlightToServiceAreasAndServices < ActiveRecord::Migration[8.1]
  def change
    %i[service_areas services].each do |table|
      add_column table, :hero_highlight, :string
      add_column table, :hero_highlight_text, :string
    end
  end
end

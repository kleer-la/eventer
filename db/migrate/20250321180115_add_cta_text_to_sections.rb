class AddCtaTextToSections < ActiveRecord::Migration[7.1]
  def change
    add_column :sections, :cta_text, :string
  end
end

class AddCtaUrlToSections < ActiveRecord::Migration[7.2]
  def change
    add_column :sections, :cta_url, :string
  end
end

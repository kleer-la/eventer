class AddSeoFieldsToServices < ActiveRecord::Migration[7.2]
  def change
    add_column :services, :seo_title, :string
    add_column :services, :seo_description, :text
  end
end

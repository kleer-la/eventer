class AddSeoDescriptionAndTabtitleToResource < ActiveRecord::Migration[7.1]
  def change
    add_column :resources, :seo_description_es, :string
    add_column :resources, :seo_description_en, :string
    add_column :resources, :tabtitle_es, :string
    add_column :resources, :tabtitle_en, :string
  end
end

class AddPublishedToResource < ActiveRecord::Migration[7.1]
  def change
    add_column :resources, :published, :boolean
    Resource.update_all(published: true)
  end
end

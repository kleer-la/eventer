class AddSlugToServices < ActiveRecord::Migration[7.1]
  def change
    add_column :services, :slug, :string
    add_index :services, :slug, unique: true

    # Generate slugs for existing records
    Service.find_each(&:save)
  end
end

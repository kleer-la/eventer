class AddBrochureToServices < ActiveRecord::Migration[7.1]
  def change
    add_column :services, :brochure, :string
  end
end

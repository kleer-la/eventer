class AddSideImageToServices < ActiveRecord::Migration[7.1]
  def change
    add_column :services, :side_image, :string
  end
end

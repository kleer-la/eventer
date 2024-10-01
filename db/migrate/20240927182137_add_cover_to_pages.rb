class AddCoverToPages < ActiveRecord::Migration[7.1]
  def change
    add_column :pages, :cover, :string, null: true
  end
end

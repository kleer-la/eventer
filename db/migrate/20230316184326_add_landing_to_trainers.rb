class AddLandingToTrainers < ActiveRecord::Migration[6.1]
  def change
    add_column :trainers, :landing, :string
  end
end

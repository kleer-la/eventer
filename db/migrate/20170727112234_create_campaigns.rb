class CreateCampaigns < ActiveRecord::Migration[5.0]
  def change
    create_table :campaigns do |t|
      t.string :codename, :index => true
      t.text :description

      t.timestamps null: true
    end
  end
end

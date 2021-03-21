class CreateCampaigns < ActiveRecord::Migration[4.2]
  def change
    create_table :campaigns do |t|
      t.string :codename, :index => true
      t.text :description

      t.timestamps null: true
    end
  end
end

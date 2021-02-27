class CreateCampaignViews < ActiveRecord::Migration[5.0]
  def change
    create_table :campaign_views do |t|
      t.string :source
      t.references :campaign
      t.references :event

      t.timestamps null: true
    end
  end
end

# frozen_string_literal: true

class CreateCampaignViews < ActiveRecord::Migration[4.2]
  def change
    create_table :campaign_views do |t|
      t.string :source
      t.references :campaign
      t.references :event

      t.timestamps null: true
    end
  end
end

# frozen_string_literal: true

class RemoveCampaignTrackingSystem < ActiveRecord::Migration[7.2]
  def up
    # Remove campaign columns from participants table
    remove_column :participants, :campaign_id, :integer if column_exists?(:participants, :campaign_id)
    remove_column :participants, :campaign_source_id, :integer if column_exists?(:participants, :campaign_source_id)
    
    # Drop campaign tracking tables
    drop_table :campaign_views if table_exists?(:campaign_views)
    drop_table :campaigns if table_exists?(:campaigns)
    drop_table :campaign_sources if table_exists?(:campaign_sources)
  end

  def down
    # Recreate campaign_sources table
    create_table :campaign_sources do |t|
      t.string :codename
      t.timestamps null: false
    end

    # Recreate campaigns table  
    create_table :campaigns do |t|
      t.string :codename
      t.timestamps null: false
    end

    # Recreate campaign_views table
    create_table :campaign_views do |t|
      t.references :event, null: false, foreign_key: true
      t.references :event_type, null: false, foreign_key: true
      t.references :campaign, null: false, foreign_key: true
      t.references :campaign_source, null: false, foreign_key: true
      t.string :element_viewed
      t.timestamps null: false
    end

    # Add campaign columns back to participants
    add_column :participants, :campaign_id, :integer
    add_column :participants, :campaign_source_id, :integer
    add_index :participants, :campaign_id
    add_index :participants, :campaign_source_id
  end
end
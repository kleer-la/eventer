# frozen_string_literal: true

class AddMarketingIndexes < ActiveRecord::Migration[4.2]
  def up
    # add_index :campaigns, :codename
    add_index :campaign_sources, :codename
    add_index :campaign_views, :campaign_id
    add_index :campaign_views, :event_id
    add_index :campaign_views, :campaign_source_id
    add_index :campaign_views, :element_viewed
  end

  def down
    # remove_index :campaigns, :codename
    remove_index :campaign_sources, :codename
    remove_index :campaign_views, :campaign_id
    remove_index :campaign_views, :event_id
    remove_index :campaign_views, :campaign_source_id
    remove_index :campaign_views, :element_viewed
  end
end

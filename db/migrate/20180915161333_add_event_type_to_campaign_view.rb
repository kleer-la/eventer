class AddEventTypeToCampaignView < ActiveRecord::Migration[4.2]
  def change
    add_column :campaign_views, :event_type_id, :integer, index: true
    add_index :campaign_views, :event_type_id

    # CampaignView.reset_column_information
    #
    # CampaignView.all.each do |cv|
    #   cv.update_attribute(:event_type, cv.event.event_type) if !cv.event.nil?
    # end
  end
end

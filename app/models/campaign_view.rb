class CampaignView < ActiveRecord::Base
  belongs_to :event
  belongs_to :event_type
  belongs_to :campaign
  belongs_to :campaign_source

  attr_accessible :campaign, :campaign_source, :event, :event_type, :element_viewed

  after_create do |view|
    view.campaign.touch unless view.campaign.nil?
    view.campaign_source.touch unless view.campaign_source.nil?
  end
end

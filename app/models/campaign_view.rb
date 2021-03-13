class CampaignView < ApplicationRecord
  belongs_to :event
  belongs_to :event_type
  belongs_to :campaign
  belongs_to :campaign_source

  after_create do |view|
    view.campaign.touch unless view.campaign.nil?
    view.campaign_source.touch unless view.campaign_source.nil?
  end
end

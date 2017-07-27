class CampaignView < ActiveRecord::Base
  belongs_to :event
  belongs_to :campaign

  attr_accessible :campaign, :source, :event
end

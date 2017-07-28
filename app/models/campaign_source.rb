class CampaignSource < ActiveRecord::Base
  has_many :campaign_views
  has_many :events, through: :campaign_views, uniq: true
  has_many :event_types, through: :events, uniq: true
  has_many :countries, through: :events, uniq: true
  has_many :participants

  attr_accessible :codename

  def display_name
    (!self.codename.nil? && self.codename != "") ? self.codename : "n/a"
  end
end

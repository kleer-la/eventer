class CampaignSource < ActiveRecord::Base
  has_many :campaign_views
  has_many :events, -> { uniq },through: :campaign_views
  has_many :event_types, -> { uniq },through: :events
  has_many :countries, -> { uniq },through: :events
  has_many :participants

  attr_accessible :codename

  def display_name
    (!self.codename.nil? && self.codename != "") ? self.codename : "n/a"
  end
end

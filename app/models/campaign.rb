class Campaign < ActiveRecord::Base
  has_many :campaign_views
  has_many :events, through: :campaign_views
  attr_accessible :codename, :description

  def display_name
    (!self.codename.nil? && self.codename != "") ? self.codename : "DEFAULT"
  end
end

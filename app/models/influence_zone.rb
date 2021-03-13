class InfluenceZone < ApplicationRecord
  belongs_to :country
  default_scope -> {order('country_id, zone_name ASC')}

  validates :tag_name, :country, :presence => true

  def display_name
    if self.country.nil?
      self.zone_name
    else
      self.zone_name == "" ? self.country.name : self.country.name+" - "+self.zone_name
    end
  end
end

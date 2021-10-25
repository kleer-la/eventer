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

  def self.find_by_country(iso_code)
    Country.find_by(iso_code: iso_code.upcase)&.influence_zones&.first
  end

end

# frozen_string_literal: true

class InfluenceZone < ApplicationRecord
  belongs_to :country
  default_scope -> { order('country_id, zone_name ASC') }

  validates :tag_name, :country, presence: true

  def display_name
    if country.nil?
      zone_name
    else
      zone_name == '' ? country.name : "#{country.name} - #{zone_name}"
    end
  end

  def self.find_by_country(iso_code)
    InfluenceZone.joins(:country).where('countries.iso_code' => iso_code).first
  end
end

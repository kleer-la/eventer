class Country < ApplicationRecord
  
  has_many :influence_zones
  
  def to_s
    iso_code + " - " +name
  end

end

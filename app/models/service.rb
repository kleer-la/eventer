class Service < ApplicationRecord
  belongs_to :service_area

  def self.ransackable_attributes(auth_object = nil)
    ["card_description", "created_at", "id", "id_value", "name", "service_area_id", "subtitle", "updated_at"]
  end

end

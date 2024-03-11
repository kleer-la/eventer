class Testimony < ApplicationRecord
  belongs_to :service
  has_rich_text :testimony

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "first_name", "id", "id_value", "last_name", "photo_url", "profile_url", "service_id", "stared", "updated_at"]
  end
  def self.ransackable_associations(auth_object = nil)
    ["rich_text_testimony", "service"]
  end
end

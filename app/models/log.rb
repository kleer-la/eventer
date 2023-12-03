class Log < ApplicationRecord
  enum area: %i[xero mail aws app]
  enum level: %i[info warn error]

  def self.log(area, level, message, details = nil)
    l = Log.new
    l.area = area
    l.level = level
    l.message = message
    l.details = details
    l.save!
  end
  def self.ransackable_attributes(auth_object = nil)
    ["area", "created_at", "details", "id", "id_value", "level", "message", "updated_at"]
  end
end

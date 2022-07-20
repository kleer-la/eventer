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

end

# frozen_string_literal: true

class Log < ApplicationRecord
  enum area: %i[xero mail aws app]
  enum level: %i[info warn error]

  def self.log(area, level, message, details = nil)
    l = Log.create!(area:, level:, message:, details:)

    Rails.logger.debug l.to_s if Rails.env.development? || Rails.env.test?
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[area created_at details id id_value level message updated_at]
  end
end

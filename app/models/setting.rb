class Setting < ApplicationRecord
  def self.get(key)
    v= Setting.where(key: key).first&.value
    v || ""
  end
end

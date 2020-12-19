class Setting < ActiveRecord::Base
  attr_accessible :key, :value

  def self.get(key)
    v= Setting.where(key: "Hi").first&.value
    v || ""
  end
end

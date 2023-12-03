# frozen_string_literal: true

class Setting < ApplicationRecord
  def self.get(key)
    v = Setting.where(key: key).first&.value
    v || ''
  end
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "key", "updated_at", "value"]
  end
end

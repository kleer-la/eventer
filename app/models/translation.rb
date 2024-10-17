# frozen_string_literal: true

class Translation < ApplicationRecord
  belongs_to :resource
  belongs_to :trainer

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at id id_value resource_id trainer_id updated_at]
  end
end

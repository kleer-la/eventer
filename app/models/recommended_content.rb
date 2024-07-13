class RecommendedContent < ApplicationRecord
  belongs_to :source, polymorphic: true
  belongs_to :target, polymorphic: true

  validates :relevance_order, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id id_value relevance_order source_id source_type target_id target_type
       updated_at]
  end
end

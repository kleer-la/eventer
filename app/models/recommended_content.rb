class RecommendedContent < ApplicationRecord
  belongs_to :source, polymorphic: true
  belongs_to :target, polymorphic: true

  validates :relevance_order, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
end

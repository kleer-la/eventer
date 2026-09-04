# frozen_string_literal: true

class RecommendedContent < ApplicationRecord
  belongs_to :source, polymorphic: true
  belongs_to :target, polymorphic: true

  validates :relevance_order, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validate :target_has_a_url_of_its_own

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id id_value relevance_order source_id source_type target_id target_type
       updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[source target]
  end

  private

  # Recommending a page only makes sense when the page is somewhere to go. An
  # overlay is section overrides for a template that is already routed
  # elsewhere, and the home page has no slug at all, so a card pointing at
  # either would render a link to nowhere.
  def target_has_a_url_of_its_own
    return unless target.is_a?(Page) && !target.flagship?

    errors.add(:target, 'is an overlay page: only flagship pages have a URL of their own')
  end
end

class Service < ApplicationRecord
  belongs_to :service_area

  has_rich_text :value_proposition
  has_rich_text :outcomes
  has_rich_text :program
  has_rich_text :target
  has_rich_text :faq

  def self.ransackable_attributes(_auth_object = nil)
    %w[card_description created_at id name service_area_id subtitle updated_at value_proposition outcomes program target faq]
  end
end

# frozen_string_literal: true

class Service < ApplicationRecord
  belongs_to :service_area

  has_rich_text :value_proposition
  has_rich_text :outcomes
  has_rich_text :program
  has_rich_text :target
  has_rich_text :faq

  validates_presence_of %i[name subtitle value_proposition outcomes program target]

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id name service_area_id subtitle updated_at value_proposition outcomes program target faq]
  end

  def outcomes_list
    return nil unless outcomes.present?

    doc = Nokogiri::HTML(outcomes.body.to_html)
    doc.css('ul li').map(&:inner_html)
  end
end

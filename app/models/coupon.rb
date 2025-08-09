# frozen_string_literal: true

class Coupon < ApplicationRecord
  include ImageReference
  references_images_in :icon
  enum :coupon_type, { codeless: 0, percent_off: 1, amount_off: 2 }
  before_validation :downcase_code

  has_and_belongs_to_many :event_types

  validates :code, length: { maximum: 20 }

  validates :percent_off, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, if: lambda {
                                                                                                           percent_off?
                                                                                                         }
  validates :amount_off, numericality: { greater_than_or_equal_to: 0 }, if: -> { amount_off? }

  # Define a method to check if it is a percent_off coupon
  def percent_off?
    coupon_type == 'percent_off'
  end

  # Define a method to check if it is an amount_off coupon
  def amount_off?
    coupon_type == 'amount_off'
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[active amount_off code coupon_type created_at display expires_on icon id id_value
       internal_name percent_off updated_at]
  end

  private

  def downcase_code
    self.code = code.strip.upcase if code.present?
  end
end

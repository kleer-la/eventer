class Coupon < ApplicationRecord
  enum coupon_type: { couponless: 0, percent_off: 1, amount_off: 2 }
  validates :code, length: { maximum: 20 }

  validates :percent_off, numericality: { greater_than: 0, less_than_or_equal_to: 100 }, if: -> { percent_off? }
  validates :amount_off, numericality: { greater_than: 0 }, if: -> { amount_off? }

  # Define a method to check if it is a percent_off coupon
  def percent_off?
    coupon_type == "percent_off"
  end

  # Define a method to check if it is an amount_off coupon
  def amount_off?
    coupon_type == "amount_off"
  end

  def self.ransackable_attributes(auth_object = nil)
    ["active", "amount_off", "code", "coupon_type", "created_at", "display", "expires_on", "icon", "id", "id_value", "internal_name", "percent_off", "updated_at"]
  end
end

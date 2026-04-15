# frozen_string_literal: true

class Booking < ApplicationRecord
  belongs_to :trainer
  belongs_to :service_area, optional: true

  validates :visitor_name, :visitor_email, :starts_at, :ends_at, presence: true
  validates :visitor_email, format: { with: /\A[\w+\-.]+@[a-z\d-]+(\.[a-z]+)*\.[a-z]+\z/i }

  enum :status, { pending: 'pending', confirmed: 'confirmed', cancelled: 'cancelled' }
end

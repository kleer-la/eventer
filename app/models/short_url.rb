class ShortUrl < ApplicationRecord
  extend FriendlyId
  friendly_id :short_code, use: :finders

  validates :original_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :short_code, presence: true, length: { in: 4..16 },
                         format: { with: /\A[a-zA-Z0-9_-]+\z/, message: 'only allows letters, numbers, hyphens, and underscores' },
                         uniqueness: { case_sensitive: true }

  before_validation :generate_short_code, on: :create, unless: :short_code_present?


  def self.ransackable_attributes(_auth_object = nil)
    %w[click_count created_at id id_value original_url short_code updated_at]
  end

  private

  def generate_short_code
    self.short_code = SecureRandom.alphanumeric(6) until unique_short_code?       
  end

  def unique_short_code?
    return false if short_code.blank?

    !ShortUrl.exists?(short_code: short_code)
  end

  def short_code_present?
    short_code.present?
  end

  def should_generate_new_friendly_id?
    short_code_changed? || super
  end

end

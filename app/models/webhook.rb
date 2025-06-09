class Webhook < ApplicationRecord
  validates :url, :event, presence: true
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  before_create :generate_secret, unless: :secret?

  private

  def generate_secret
    self.secret = SecureRandom.hex(32)
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[active created_at event id secret updated_at url]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end

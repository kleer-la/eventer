class Webhook < ApplicationRecord
  belongs_to :responsible, class_name: 'Trainer', foreign_key: 'responsible_id'
  
  validates :url, :event, :responsible_id, presence: true
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  before_create :generate_secret, unless: :secret?

  private

  def generate_secret
    self.secret = SecureRandom.hex(32)
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[active created_at event id secret updated_at url responsible_id comment]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[responsible]
  end
end

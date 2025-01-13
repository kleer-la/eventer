class Contact < ApplicationRecord
  enum trigger_type: { contact_form: 0, download_form: 1 }
  enum status: { pending: 0, processed: 1, failed: 2 }

  validates :trigger_type, :email, :form_data, presence: true

  scope :pending, -> { where(status: :pending) }
  scope :processed, -> { where(status: :processed) }
  scope :failed, -> { where(status: :failed) }
  scope :last_24h, -> { where('created_at >= ?', 25.hours.ago) } # to handle  limit cases

  def self.stats
    {
      total: count,
      last_24h: last_24h.count,
      by_type: group(:trigger_type).count,
      by_status: group(:status).count
    }
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at email form_data id id_value processed_at status trigger_type updated_at
       resource_slug can_we_contact suscribe]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end

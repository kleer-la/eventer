class Contact < ApplicationRecord
  enum trigger_type: { contact_form: 0, download_form: 1 }
  enum status: { pending: 0, processed: 1, failed: 2 }

  validates :trigger_type, :email, :form_data, presence: true

  scope :unprocessed, -> { where(status: :pending) }
  scope :last_24h, -> { where('created_at >= ?', 25.hours.ago) } # to handle  limit cases
end

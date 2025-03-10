class Contact < ApplicationRecord
  enum trigger_type: { contact_form: 0, download_form: 1, assessment_submission: 2 }
  enum status: { pending: 0, processed: 1, failed: 2, processing: 3 }

  belongs_to :assessment, optional: true
  has_many :responses, dependent: :destroy

  validates :trigger_type, :email, :form_data, presence: true

  after_create :update_form_fields

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
       resource_slug can_we_contact suscribe assessment_report_url assessment_report_generated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[assessment responses]
  end

  private

  def update_form_fields
    update_columns(
      resource_slug: form_data['resource_slug'],
      can_we_contact: boolean_value(form_data['can_we_contact']),
      suscribe: boolean_value(form_data['suscribe'])
    )
  end

  def boolean_value(value)
    return false if value.nil? || value.blank?

    value.to_s.downcase.in?(%w[true 1 yes])
  end
end

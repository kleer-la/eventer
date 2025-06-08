# frozen_string_literal: true

class Contact < ApplicationRecord
  enum :trigger_type, { contact_form: 0, download_form: 1, assessment_submission: 2 }
  enum :status, { pending: 0, in_progress: 1, completed: 2, failed: 3 }

  belongs_to :assessment, optional: true
  has_many :responses, dependent: :destroy

  validates :trigger_type, :email, :form_data, presence: true
  # validates :name, :company, presence: true

  after_create :update_form_fields
  after_create :trigger_webhook

  scope :pending, -> { where(status: :pending) }
  scope :completed, -> { where(status: :completed) }
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

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at email form_data id id_value processed_at status trigger_type updated_at
       resource_slug content_updates_opt_in newsletter_opt_in newsletter_added assessment_report_url
       assessment_report_generated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[assessment responses]
  end

  private

  def update_form_fields
    update_columns(
      resource_slug: form_data['resource_slug'],
      content_updates_opt_in: boolean_value(form_data['content_updates_opt_in']),
      newsletter_opt_in: boolean_value(form_data['newsletter_opt_in']),
      name: form_data&.dig('name'),
      company: form_data&.dig('company')
    )
  end

  def boolean_value(value)
    return false if value.nil? || value.blank?

    value.to_s.downcase.in?(%w[true 1 yes])
  end

  def trigger_webhook
    WebhookService.new(self).delay.deliver
  end
end

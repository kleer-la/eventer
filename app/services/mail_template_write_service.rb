# frozen_string_literal: true

class MailTemplateWriteService < ContentWriteService
  self.model = MailTemplate
  self.editable_fields = %i[identifier trigger_type lang subject content to cc active delivery_schedule
                            resource_slug]
  self.long_fields = %w[content]
  # Sending is decided by `active`, `delivery_schedule` and the contact's language; there is no publish flag.
  self.publication_flag = nil

  # The Liquid variables a contact's form_data carries, as the admin hint lists them.
  KNOWN_VARIABLES = %w[name email company message page language subject context resource_slug
                       resource_title_es resource_title_en resource_getit_es resource_getit_en].freeze

  private

  def label = @record.identifier

  def model_warnings
    unknown = %w[subject content to cc].flat_map { |f| @record.public_send(f).to_s.scan(/\{\{\s*(\w+)/).flatten }
                                       .uniq - KNOWN_VARIABLES
    return [] if unknown.empty?

    ["#{unknown.map { |v| "{{#{v}}}" }.join(', ')}: not something the forms send, it will render empty. " \
     "Known variables: #{KNOWN_VARIABLES.join(', ')}"]
  end
end

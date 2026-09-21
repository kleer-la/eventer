# frozen_string_literal: true

# What the site's forms sent in — a contact message, a resource download
# request, an assessment — read-only: the same view as Mail → Contacts in the
# admin. One call answers "did this person request that resource?", which is
# what lets someone into session-handoff (#203).
class ContactsTool < AuthenticatedTool
  tool_name 'contacts'
  requires_permission :read, Contact

  OPERATIONS = %w[search get].freeze

  description <<~MD
    Contacts: what the site's forms sent in — a contact message
    (contact_form), a resource download request (download_form) or an
    assessment (assessment_submission). Read-only.

    operation=search (default): newest first, filtered by query (email or
    name, case-insensitive), trigger_type, resource_slug, from, to. Answers
    who, what and when, not the form itself. A download request for
    `session-handoff` with a given email is what lets that email sign in to
    handoff.kleer.la, so this is where to look when someone cannot get in.
    operation=get: one contact (`id`) with everything the form sent.

    These are personal data: the same permissions as the admin apply.
  MD

  arguments do
    optional(:operation).filled(:string).description("'search' (default) or 'get'")
    optional(:id).filled(:integer).description('get: numeric id of the contact')
    optional(:query).filled(:string).description('search: substring of the email or the name')
    optional(:trigger_type).filled(:string).description('search: contact_form | download_form | assessment_submission')
    optional(:resource_slug).filled(:string).description('search: download requests of this resource')
    optional(:from).filled(:string).description('search: only contacts on or after this date, YYYY-MM-DD')
    optional(:to).filled(:string).description('search: only contacts on or before this date, YYYY-MM-DD')
    optional(:limit).filled(:integer).description("search: how many (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
  end

  def call(operation: 'search', **args)
    return unknown_operation(operation) unless OPERATIONS.include?(operation)

    send(operation, **args)
  rescue Date::Error => e
    error("#{e.message}. Dates go as YYYY-MM-DD.")
  end

  private

  def search(query: nil, trigger_type: nil, resource_slug: nil, from: nil, to: nil, limit: DEFAULT_LIMIT, **)
    if trigger_type.present? && Contact.trigger_types.exclude?(trigger_type)
      return error("Unknown trigger_type #{trigger_type.inspect}. Valid ones: #{Contact.trigger_types.keys.join(', ')}")
    end

    scope = filtered(Contact.order(created_at: :desc), query: query, trigger_type: trigger_type,
                                                       resource_slug: resource_slug, from: from, to: to)
    contacts = scope.limit(limit.clamp(1, MAX_LIMIT)).map { |contact| summary(contact) }
    listing(:contacts, contacts, total: scope.count, narrow: 'query, trigger_type, resource_slug, from or to')
  end

  def filtered(scope, query:, trigger_type:, resource_slug:, from:, to:)
    scope = scope.where('LOWER(email) LIKE :q OR LOWER(name) LIKE :q', q: "%#{query.downcase}%") if query.present?
    scope = scope.where(trigger_type: trigger_type) if trigger_type.present?
    scope = scope.where(resource_slug: resource_slug) if resource_slug.present?
    scope = scope.where(created_at: Date.parse(from).beginning_of_day..) if from.present?
    scope = scope.where(created_at: ..Date.parse(to).end_of_day) if to.present?
    scope
  end

  def summary(contact)
    { id: contact.id, trigger_type: contact.trigger_type, email: contact.email, name: contact.name,
      company: contact.company, resource_slug: contact.resource_slug, language: contact.form_data['language'],
      status: contact.status, created_at: contact.created_at }
  end

  def get(id: nil, **)
    contact = Contact.find_by(id: id)
    return error("No contact with id #{id.inspect}") if contact.nil?

    summary(contact).merge(form_data: contact.form_data, processed_at: contact.processed_at,
                           newsletter_opt_in: contact.newsletter_opt_in,
                           content_updates_opt_in: contact.content_updates_opt_in).to_json
  end
end

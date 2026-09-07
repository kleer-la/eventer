# frozen_string_literal: true

class GetEventTypeTool < AuthenticatedTool
  tool_name 'get_event_type'
  requires_permission :read, EventType

  description <<~MD
    Returns one course type in full, by slug or id: the blocks that make up its
    page on the site (description, recipients, program, goal, learnings,
    takeaways, faq), what the certificate says, and who teaches it.

    Read it before editing, so the change is made against the current text.
  MD

  BLOCKS = %i[description recipients program goal learnings takeaways faq].freeze

  arguments do
    required(:id).filled(:string).description('Course slug (preferred) or numeric id')
  end

  def call(id:)
    event_type = find(id)
    identity(event_type)
      .merge(flags(event_type))
      .merge(blocks: BLOCKS.index_with { |field| event_type.public_send(field).to_s })
      .to_json
  rescue ActiveRecord::RecordNotFound
    { status: 'error', errors: ["No course type with slug or id #{id.inspect}"] }.to_json
  end

  private

  def identity(event_type)
    { id: event_type.id, slug: event_type.slug, name: event_type.name, lang: event_type.lang,
      subtitle: event_type.subtitle, elevator_pitch: event_type.elevator_pitch,
      tag_name: event_type.tag_name, duration: event_type.duration,
      trainers: event_type.trainers.map(&:name) }
  end

  # What decides how the page behaves and what the certificate says: whether it
  # is on sale, whether it is indexed, and which seal it carries.
  def flags(event_type)
    { in_catalog: event_type.include_in_catalog, deleted: event_type.deleted, noindex: event_type.noindex,
      is_kleer_certification: event_type.is_kleer_certification, csd_eligible: event_type.csd_eligible,
      kleer_cert_seal_image: event_type.kleer_cert_seal_image, new_version: event_type.new_version,
      seo_title: event_type.seo_title, external_site_url: event_type.external_site_url }
  end

  # The slug is derived, not stored — "<id>-<name parameterised>" — so a lookup
  # takes the leading id and a bare id works too.
  def find(id)
    EventType.find(id.to_s[/\A\d+/] || id)
  end
end

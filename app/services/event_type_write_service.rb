# frozen_string_literal: true

# An event type written from the chat: the course template a certificate names.
#
# The same record that backs a certificate also backs the course's page on the
# site, and whether that page is on sale (`include_in_catalog`) is a decision
# about what Kleer sells. So it is guarded the way `published` is for content:
# only whoever may `set_include_in_catalog` (the publisher role, as in the admin
# form) changes it, and a course is always created out of the catalog.
class EventTypeWriteService < ContentWriteService
  self.model = EventType
  self.editable_fields = %i[name description recipients program elevator_pitch goal learnings takeaways
                            faq duration lang tag_name subtitle is_kleer_certification
                            kleer_cert_seal_image csd_eligible new_version external_site_url]
  self.long_fields = %w[description program recipients goal learnings takeaways faq]
  self.publication_flag = :include_in_catalog
  self.publication_permission = :set_include_in_catalog

  include TrainerAssignment

  def initialize(in_catalog: nil, **args)
    super(published: in_catalog, **args)
  end

  private

  def assign
    super
    @record.include_in_catalog = false if @record.new_record?
  end

  def model_warnings
    return [] unless @record.new_record?

    ['It is created out of the public catalog (include_in_catalog is false). Once it is ready to be on ' \
     'sale on the site, update it with in_catalog=true.']
  end

  # A new course is forced out of the catalog (nil → false): that is not taking
  # it off sale, and model_warnings already says so.
  def unpublishing? = !@record.new_record? && super

  def publication_refusal = 'You are not allowed to change whether this course is in the public catalog'
  def publishing_warning = 'It is being added to the public catalog: the course goes on sale on the site.'

  def unpublishing_warning
    note = 'It is being taken out of the public catalog: the course is no longer on sale on the site.'
    return note if @record.external_site_url.present?

    "#{note} If something replaces it, set external_site_url so its page sends visitors there."
  end
end

# frozen_string_literal: true

# Writes a Testimony for the MCP tool. What it is about is a Service (by id or
# slug) or an EventType (by id): exactly one on create, optional on update to
# move it. Starring (the `stared` column) is what puts it on the page, so it
# rides the publication flag and its warnings.
class TestimonyWriteService < ContentWriteService
  self.model = Testimony
  self.editable_fields = %i[first_name last_name testimony profile_url photo_url]
  self.rich_text_fields = %i[testimony]
  self.publication_flag = :stared
  self.guarded_publication = false

  WHAT_ABOUT = 'Say what it is about with service or event_type, exactly one ' \
               '(service: id or slug; event_type: id).'

  def initialize(service: nil, event_type: nil, starred: nil, **args)
    super(published: starred, **args)
    @service = service
    @event_type = event_type
  end

  private

  def assign
    @record.stared = false if @record.new_record? && @record.stared.nil?
    super
    assign_testimonial
  end

  def assign_testimonial
    given = [@service, @event_type].count(&:present?)
    return if given.zero? && @record.persisted?
    return errors << WHAT_ABOUT unless given == 1

    subject = @service.present? ? find_service : find_event_type
    @record.testimonial = subject if subject
  end

  def find_service
    Service.friendly.find(@service)
  rescue ActiveRecord::RecordNotFound
    errors << "Unknown service #{@service.inspect}. Pass its id or slug (see the services tool)."
    nil
  end

  def find_event_type
    EventType.find(@event_type.to_s[/\A\d+/] || @event_type)
  rescue ActiveRecord::RecordNotFound
    errors << "Unknown event_type #{@event_type.inspect}. Pass its numeric id (see the event_types tool)."
    nil
  end

  def model_warnings
    subject = @record.testimonial
    return [] unless subject

    area = subject.is_a?(Service) && subject.service_area ? " (area #{subject.service_area.name})" : ''
    about = ["About: #{subject.class.model_name.human} #{subject.name}#{area}."]
    return about unless publishing?

    about + ['Starred: it shows on the page of that course, or of the area its service belongs to.']
  end

  # A new testimony starts unstarred; that is not "disappearing from the site".
  def unpublishing? = super && @record.persisted?

  def label = [@record.first_name, @record.last_name].compact.join(' ')
end

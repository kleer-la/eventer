# frozen_string_literal: true

# An event created from the chat: almost always a course already given, being
# loaded so its participants can get their certificates.
#
# Hence the defaults: private and free. A public event is a course on sale, and
# nothing about "load the training we ran in April" says to put one on the site.
class EventWriteService < ContentWriteService
  self.model = Event
  self.editable_fields = %i[date city place address capacity list_price currency_iso_code duration
                            start_time end_time mode visibility_type time_zone_name finish_date
                            specific_subtitle monitor_email]
  self.publication_flag = nil

  # Only for a new record: on an edit, unmentioned fields keep their value.
  DEFAULTS = { visibility_type: 'pr', mode: 'cl', capacity: 20, list_price: 0 }.freeze

  def initialize(event_type_id: nil, country: nil, trainer: nil, trainer2: nil, **args)
    super(**args)
    @event_type_id = event_type_id
    @country_name = country
    @trainer_name = trainer
    @trainer2_name = trainer2
    @fields = DEFAULTS.merge(@fields) if @record.new_record?
  end

  private

  def assign
    super
    assign_event_type
    assign_country
    assign_trainers
  end

  def assign_event_type
    return if @event_type_id.blank?

    event_type = EventType.find_by(id: @event_type_id)
    return errors << "Unknown event type #{@event_type_id}. Use list_event_types to find its id." if event_type.nil?

    @record.event_type = event_type
  end

  # By name as the admin shows it, or by ISO code — a chat that has 'AR' should
  # not have to look up that it is called Argentina here.
  def assign_country
    return if @country_name.blank?

    country = Country.find_by(name: @country_name) || Country.find_by(iso_code: @country_name.to_s.upcase)
    if country.nil?
      return errors << "Unknown country #{@country_name.inspect}. " \
                       "Existing ones: #{Country.order(:name).pluck(:name).join(', ')}"
    end

    @record.country = country
  end

  def assign_trainers
    @record.trainer = find_trainer(@trainer_name) if @trainer_name.present?
    @record.trainer2 = find_trainer(@trainer2_name) if @trainer2_name.present?
  end

  def find_trainer(name)
    trainer = Trainer.find_by(name: name)
    return trainer if trainer

    errors << "Unknown trainer #{name.inspect}. " \
              "Existing ones: #{Trainer.order(:name).pluck(:name).join(', ')}"
    nil
  end

  def label = @record.event_type&.name

  def model_warnings
    return [] unless @record.new_record? && @record.visibility_type == 'pr'

    ['It is private (visibility_type "pr"), so it does not show up on the site or take registrations.']
  end
end

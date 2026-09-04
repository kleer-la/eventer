# frozen_string_literal: true

# A participant loaded from the chat, usually one who was in the room but never
# in the system.
#
# The verification code is not something the caller sets: Participant generates
# it on create, and it is what the certificate carries and what someone types at
# kleer.la/certificado — so it is handed back after saving.
class ParticipantWriteService < ContentWriteService
  self.model = Participant
  self.editable_fields = %i[fname lname email phone id_number address company_name notes quantity status]
  self.long_fields = %w[notes]
  self.publication_flag = nil

  CERTIFIABLE = [Participant::STATUS[:attended], Participant::STATUS[:certified]].freeze

  def initialize(event_id: nil, influence_zone: nil, **args)
    super(**args)
    @event_id = event_id
    @influence_zone_name = influence_zone
  end

  private

  def assign
    super
    assign_event
    assign_influence_zone
  end

  def assign_event
    return if @event_id.blank?

    event = Event.find_by(id: @event_id)
    return errors << "Unknown event #{@event_id}. Use list_events to find its id." if event.nil?

    @record.event = event
  end

  def assign_influence_zone
    return if @influence_zone_name.blank?

    zone = InfluenceZone.find_by(tag_name: @influence_zone_name) ||
           InfluenceZone.find_by(zone_name: @influence_zone_name)
    return errors << "Unknown influence zone #{@influence_zone_name.inspect}." if zone.nil?

    @record.influence_zone = zone
  end

  def label = "#{@record.fname} #{@record.lname}".strip

  def saved_extras = { verification_code: @record.verification_code }

  def model_warnings
    return [] if CERTIFIABLE.include?(@record.status)

    ["Status is #{@record.human_status} (#{@record.status}): no certificate can be issued until it is " \
     'Presente (A) or Certificado (K).']
  end
end

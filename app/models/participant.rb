# frozen_string_literal: true

require 'valid_email'

class Participant < ApplicationRecord
  belongs_to :event
  belongs_to :influence_zone, optional: true
  belongs_to :campaign, optional: true
  belongs_to :campaign_source, optional: true

  before_create do
    self.fname = fname.strip
    self.lname = lname.strip
    self.company_name = "#{fname} #{lname}" unless company_name.present?
  end

  validates :email, :fname, :lname, :event, presence: true
  # validates :address, :phone, :influence_zone, :id_number

  validates :email, email: true
  validates_acceptance_of :accept_terms, message: 'No podemos contactarlo si no acepta los términos.'

  def self.val_range(record, attr, value, msg, from, to)
    record.errors.add(attr, msg) unless value.nil? || (value >= from && value <= to)
  end

  validates_each :event_rating do |record, attr, value|
    val_range(record, attr, value, :event_rating_should_be_between_1_and_5, 1, 5)
  end

  validates_each :trainer_rating do |record, attr, value|
    val_range(record, attr, value, :trainer_rating_should_be_between_1_and_5, 1, 5)
  end

  validates_each :promoter_score do |record, attr, value|
    val_range(record, attr, value, :promoter_score_should_be_between_0_and_10, 0, 10)
  end

  STATUS = {
    new: 'N',
    contacted: 'T',
    confirmed: 'C',
    attended: 'A',
    certified: 'K',
    deffered: 'D',
    cancelled: 'X'
  }.freeze

  STATUS_DESC = {
    'N' => 'Nuevo',
    'T' => 'Contactado',
    'C' => 'Confirmado',
    'A' => 'Presente',
    'K' => 'Certificado',
    'D' => 'Pospuesto',
    'X' => 'Cancelado'
  }.freeze

  PAYMENT_TYPE = {
    cash: 'C',
    mercado_pago: 'MP',
    paypal: 'PP',
    wire_transfer: 'WT',
    deposit: 'D'
  }.freeze

  scope :new_ones, -> { where(status: STATUS[:new]) }
  scope :confirmed, -> { where(status: STATUS[:confirmed]) }
  scope :contacted, -> { where(status: STATUS[:contacted]) }
  scope :cancelled, -> { where(status: STATUS[:cancelled]) }
  scope :deffered, -> { where(status: STATUS[:deffered]) }
  scope :attended, -> { where(status: STATUS[:attended]) }
  scope :certified, -> { where(status: STATUS[:certified]) }
  scope :attended?, lambda {
                      where('status=? OR status=? OR status=?',
                            STATUS[:confirmed], STATUS[:attended], STATUS[:certified])
                    }
  scope :to_certify, -> { where('status=? OR status=?', STATUS[:attended], STATUS[:certified]) }

  scope :surveyed, -> { where('trainer_rating > 0 AND event_rating > 0 and promoter_score > -1') }
  scope :cotrainer_surveyed, -> { where('trainer2_rating > 0 AND event_rating > 0 and promoter_score > -1') }
  scope :promoter, -> { where('promoter_score >= 9') }
  scope :passive, -> { where('promoter_score <= 8 AND promoter_score >= 7') }
  scope :detractor, -> { where('promoter_score <= 6') }

  after_initialize :initialize_defaults

  after_create do |participant|
    participant.campaign&.touch
    participant.campaign_source&.touch
  end

  comma do
    lname 'Apellido'
    fname 'Nombre'
    email 'Email'
    phone 'Telefono'
    human_status 'Estado'
    influence_zone_name 'Ciudad/Provincia/Región'
    influence_zone_country 'País'
    influence_zone_tag 'Zona de Influencia (tag)'
  end

  def self.to_csv(collection)
    attributes = %w[fname lname email human_status]

    CSV.generate(headers: true) do |csv|
      csv << attributes
      collection.each do |participant|
        csv << attributes.map { |attr| participant.send(attr) }
      end
    end
  end


  def initialize_defaults
    return unless new_record?

    self.status = STATUS[:new] if status.nil?
    self.verification_code = Digest::SHA1.hexdigest([Time.now, rand].join)[1..20].upcase
    self.influence_zone = InfluenceZone.first
  end

  def human_status
    STATUS_DESC[status] || '--?--'
  end

  def status_sort_order
    ('NTCAKDX'.index(status) || 7) + 1
  end

  def confirm!
    self.status = STATUS[:confirmed]
  end

  def contact!
    self.status = STATUS[:contacted]
    if !notes.nil?
      self.notes += "\n"
    else
      self.notes = ''
    end
    self.notes += "#{Date.today.strftime('%d-%b')}: Info (auto)"
  end

  def attend!
    self.status = STATUS[:attended]
  end

  def certify!
    self.status = STATUS[:certified]
  end

  def present?
    status == STATUS[:attended]
  end

  def certified?
    status == STATUS[:certified]
  end

  def cancelled?
    status == STATUS[:cancelled]
  end
  def cancelled!
    self.status = STATUS[:cancelled]
  end

  def could_receive_certificate?
    present? || certified?
  end

  def paid!
    return if self.paid?
    self.status = STATUS[:confirmed] 
    self.is_payed = true
  end
  def paid?
    # TODO is_payed seems to be redundant, could be removed?
    (self.status == STATUS[:confirmed]) && self.is_payed
  end

  def influence_zone_tag
    influence_zone.nil? ? '' : influence_zone.tag_name
  end

  def influence_zone_name
    influence_zone.nil? ? '' : influence_zone.zone_name
  end

  def influence_zone_country
    if !influence_zone.nil? && !influence_zone.country.nil?
      influence_zone.country.name
    else
      ''
    end
  end

  def filestore(store = nil)
    @store = store || @store || FileStoreService.create_s3
  end

  def generate_certificate
    certificate_url = {}
    %w[A4 LETTER].each do |s|
      certificate_filename = ParticipantsHelper.generate_certificate(self, s, filestore)
      certificate_url[s] = ParticipantsHelper.upload_certificate(certificate_filename)
    end
    certificate_url
  end

  def generate_certificate_and_notify
    certificate_url = generate_certificate
    EventMailer.send_certificate(self, certificate_url['A4'], certificate_url['LETTER']).deliver
  end

  def self.parse_line(participant_data_line)
    attributes = participant_data_line.split("\t")
    attributes = participant_data_line.split(',') if attributes.size == 1
    attributes.map(&:strip)
  end

  def self.create_from_batch_line(participant_data_line, event, influence_zone, status)
    attributes = parse_line(participant_data_line)

    (return false) unless attributes.size >= 3
    Participant.new(
      fname: attributes[1],
      lname: attributes[0],
      email: attributes[2],
      phone: (attributes[3] || 'N/A'),
      id_number: 'Batch load', address: 'Batch load', notes: 'Batch load',
      event_id: event.id, influence_zone_id: influence_zone.id, status: status
    ).save
  end

  def self.batch_load(batch, event, influence_zone, status)
    errored_lines = []

    batch.lines.each do |participant_data_line|
      next if Participant.create_from_batch_line(participant_data_line, event, influence_zone, status)

      errored_lines << "'#{participant_data_line.strip}'"
    end
    [batch.lines.count - errored_lines.count, errored_lines.count, errored_lines.join(',')]
  end

  def self.search(searching, page, per_page)
    s = searching.downcase
    offset_value = per_page * (page - 1)
  
    participants = Participant.where("lower(fname || ' ' || lname || verification_code) LIKE ?", "%#{s}%")
                              .offset(offset_value)
                              .limit(per_page)
  
    participants
  end

  def self.search_by_invoice(invoice_id)
    Participant.where(invoice_id: invoice_id)[0]
  end

  def accept_terms
    # Placeholder for accepting terms & conditions
  end
end

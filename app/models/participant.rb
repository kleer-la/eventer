# encoding: utf-8
require 'valid_email'

class Participant < ApplicationRecord
  belongs_to :event
  belongs_to :influence_zone
  belongs_to :campaign
  belongs_to :campaign_source

  validates :email, :fname, :lname, :phone, :event, :influence_zone, :id_number, :address, :presence => true

  validates :email, :email => true
  validates_acceptance_of :accept_terms, message: 'No podemos contactarlo si no acepta los términos.'

  def self.val_range(record, attr, value, msg, from, to)
    record.errors.add(attr, msg) unless value.nil? || (value >= from && value <= to)
  end

  validates_each :event_rating do |record, attr, value|
    self.val_range(record, attr, value, :event_rating_should_be_between_1_and_5, 1, 5)
#      record.errors.add(attr, :event_rating_should_be_between_1_and_5) unless value.nil? || (value >= 1 && value <= 5)
  end

  validates_each :trainer_rating do |record, attr, value|
    self.val_range(record, attr, value, :trainer_rating_should_be_between_1_and_5, 1, 5)
#      record.errors.add(attr, :trainer_rating_should_be_between_1_and_5) unless value.nil? || (value >= 1 && value <= 5)
  end

  validates_each :promoter_score do |record, attr, value|
    self.val_range(record, attr, value, :promoter_score_should_be_between_0_and_10, 0, 10)
#      record.errors.add(attr, :promoter_score_should_be_between_0_and_10) unless value.nil? || (value >= 0 && value <= 10)
  end

  STATUS= {
    :new => "N",
    :contacted => "T",
    :confirmed => "C",
    :attended => "A",
    :certified => "K",
    :deffered => "D",
    :cancelled => "X"
  }

  STATUS_DESC= {
    "N" => 'Nuevo',
    "T" => 'Contactado',
    "C" => 'Confirmado',
    "A"  => 'Presente',
    "K"  => 'Certificado',
    "D" => 'Pospuesto',
    "X" => 'Cancelado'
  }

  PAYMENT_TYPE= {
    :cash => "C",
    :mercado_pago => "MP",
    :paypal => "PP",
    :wire_transfer => "WT",
    :deposit => "D"
  }

  scope :new_ones, -> {where(:status => STATUS[:new])}
  scope :confirmed, -> {where(:status => STATUS[:confirmed])}
  scope :contacted, -> {where(:status => STATUS[:contacted])}
  scope :cancelled, -> {where(:status => STATUS[:cancelled])}
  scope :deffered, -> {where(:status => STATUS[:deffered])}
  scope :attended, -> {where(:status => STATUS[:attended])}
  scope :certified, -> {where(:status => STATUS[:certified])}
  scope :confirmed_or_attended, -> {where("status=? OR status=?", STATUS[:confirmed], STATUS[:attended])}

  scope :surveyed, -> {where('trainer_rating > 0 AND event_rating > 0 and promoter_score > -1')}
  scope :cotrainer_surveyed, -> {where('trainer2_rating > 0 AND event_rating > 0 and promoter_score > -1')}
  scope :promoter, -> {where('promoter_score >= 9')}
  scope :passive, -> {where('promoter_score <= 8 AND promoter_score >= 7')}
  scope :detractor, -> {where('promoter_score <= 6')}

  after_initialize :initialize_defaults

  after_create do |participant|
    participant.campaign.touch unless participant.campaign.nil?
    participant.campaign_source.touch unless participant.campaign_source.nil?
  end

  comma do
    self.lname 'Apellido'
    self.fname 'Nombre'
    self.email 'Email'
    self.phone 'Telefono'
    self.human_status 'Estado'
    self.influence_zone_name 'Ciudad/Provincia/Región'
    self.influence_zone_country 'País'
    self.influence_zone_tag 'Zona de Influencia (tag)'
  end

  def initialize_defaults
    if new_record?
      self.status = STATUS[:new] unless !self.status.nil?
      self.verification_code = Digest::SHA1.hexdigest([Time.now, rand].join)[1..20].upcase
    end
  end

  def human_status
    STATUS_DESC[self.status] || '--?--'
  end

  def status_sort_order
    ("NTCAKDX".index(self.status) || 7)+1
  end

  def confirm!
    self.status = STATUS[:confirmed]
  end

  def contact!
    self.status = STATUS[:contacted]
    if !self.notes.nil?
      self.notes += "\n"
    else
      self.notes = ""
    end
    self.notes += "#{Date.today.strftime('%d-%b')}: Info (auto)"
  end

  def attend!
    self.status = STATUS[:attended]
  end

  def certify!
    self.status = STATUS[:certified]
  end

  def is_present?
    self.status == STATUS[:attended]
  end

  def is_certified?
    self.status == STATUS[:certified]
  end

  def could_receive_certificate?
    is_present? || is_certified?
  end

  def influence_zone_tag
    self.influence_zone.nil? ? "" : self.influence_zone.tag_name
  end

  def influence_zone_name
    self.influence_zone.nil? ? "" : self.influence_zone.zone_name
  end

  def influence_zone_country
    if !self.influence_zone.nil? && !self.influence_zone.country.nil?
      self.influence_zone.country.name
    else
      ""
    end
  end

  def filestore(store=nil)
    @store= store || @store || FileStoreService.createS3
  end

  def generate_certificate
    certificate_url={}
    ['A4', 'LETTER'].each { |s|
      certificate_filename = ParticipantsHelper::generate_certificate( self, s, self.filestore)
      certificate_url[s] = ParticipantsHelper::upload_certificate( certificate_filename )
    }
    certificate_url
  end

  def generate_certificate_and_notify
    certificate_url= generate_certificate
    EventMailer.send_certificate(self, certificate_url['A4'], certificate_url['LETTER']).deliver
  end

  def self.parse_line(participant_data_line)
    attributes = participant_data_line.split("\t")
    if attributes.size == 1
      attributes = participant_data_line.split(",")
    end
    attributes
  end

  def self.create_from_batch_line(participant_data_line, event, influence_zone, status)
    attributes= parse_line(participant_data_line)

    if attributes.size >= 3
      Participant.new(
        :fname => attributes[1].strip,
        :lname => attributes[0].strip,
        :email => attributes[2].strip,
        :phone => (attributes[3] || "N/A").strip,
        :id_number => "Batch load",
        :address => "Batch load",
        :event_id => event.id,
        :notes => "Batch load",
        :influence_zone_id => influence_zone.id,
        :status => status
      ).save
    else
      false
    end

  end

  def self.search(searching)
    s= searching.downcase
    Participant.select {|p| (p.fname + ' ' + p.lname + p.verification_code).downcase.include?(s)}
  end

  def accept_terms
    #Placeholder for accepting terms & conditions
  end

end

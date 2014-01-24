# encoding: utf-8
require 'valid_email'
require 'mercadopago'

class Participant < ActiveRecord::Base
  belongs_to :event
  belongs_to :influence_zone
  
  attr_accessible :email, :fname, :lname, :phone, :event_id, :status, :notes, :influence_zone_id, :influence_zone
  
  validates :email, :fname, :lname, :phone, :event, :influence_zone, :presence => true
  
  validates :email, :email => true
  
  scope :new_ones, where(:status => "N")
  scope :confirmed, where(:status => "C")
  scope :contacted, where(:status => "T")
  scope :cancelled, where(:status => "X")
  scope :deffered, where(:status => "D")
  scope :attended, where(:status => "A")
  
  after_initialize :initialize_defaults
  
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
      self.status = "N"
    end
  end
  
  def human_status
    if self.status == "N"
      return "Nuevo"
    elsif self.status == "T"
      return "Contactado"
    elsif self.status == "C"
      return "Confirmado"
    elsif self.status == "D"
      return "Pospuesto"
    elsif self.status == "X"
      return "Cancelado"
    elsif self.status == "A"
      return "Presente"
    end
  end
  
  def status_sort_order
    if self.status == "N"
      return 1
    elsif self.status == "T"
      return 2
    elsif self.status == "C"
      return 3
    elsif self.status == "A"
      return 4
    elsif self.status == "D"
      return 5
    elsif self.status == "X"
      return 6
    else
      return 7
    end
  end
  
  def confirm!
    self.status = "C"
  end
  
  def contact!
    self.status = "T"
    if !self.notes.nil?
      self.notes += "\n"
    else
      self.notes = ""
    end
    self.notes += "#{Date.today.strftime('%d-%b')}: Info (auto)"
  end
  
  def attend!
    self.status = "A"
  end
  
  def is_present?
    (self.status == "A")
  end
  
  def influence_zone_tag
    self.influence_zone.nil? ? "" : self.influence_zone.tag_name
  end
  
  def influence_zone_name
    self.influence_zone.nil? ? "" : self.influence_zone.zone_name
  end
  
  def influence_zone_country
    if !self.influence_zone.nil?
      self.influence_zone.country.nil? ? "" : self.influence_zone.country.name
    else
      ""
    end
  end
  
  def mp_checkout_ar_for_list_price
    mp_checkout_ar
  end
  
  def mp_checkout_ar_for_eb_price
    mp_checkout_ar
  end
  
  def mp_checkout_ar
    mp_client_id_ar = ENV["KEVENTER_MP_CLIENT_ID_AR"]
    mp_client_secret_ar = ENV["KEVENTER_MP_CLIENT_SECRET_AR"]
    mp = MercadoPago.new( mp_client_id_ar , mp_client_secret_ar )
    
    preferenceData = { 
                    "items" => Array[
                      {
                        "title" => "sdk-ruby", 
                        "quantity" => 1, 
                        "unit_price" => 10.2, 
                        "currency_id" => "ARS"
                      }
                    ]
                  }
    
    preference = mp.create_preference(preferenceData)

    preference['response']['init_point']
  end
  
end

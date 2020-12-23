# encoding: utf-8
require 'factory_bot'

FactoryBot.define do

  factory :campaign_source do
    codename "source1"
  end

  factory :campaign do
    codename "campaña1"
  end

  factory :user do
    email 'user@test.com'
    password 'please'
    password_confirmation 'please'
  end

  factory :admin_role, :class => Role do
    name :administrator
  end

  factory :comercial_role, :class => Role do
    name :comercial
  end

  factory :administrator, :class => User do
    email 'admin@user.com'
    password 'please'
    password_confirmation 'please'
    roles [ FactoryBot.create(:admin_role) ]
  end

  factory :comercial, :class => User do
    email 'comercial@user.com'
    password 'please'
    password_confirmation 'please'
    roles [ FactoryBot.create(:comercial_role) ]
  end

  factory :country do
    name "Argentina"
    iso_code "AR"
  end

  factory :trainer do
    name "Juan Alberto"
    signature_image "PT.png"
    signature_credentials "Agile Coach & Trainer"
  end

  factory :trainer2, :class => Trainer do
    name "Juan Torto"
    signature_image "JG.png"
    signature_credentials "Agile Coach & Trainer2"
  end

  factory :category do
    name "Negocios"
    description "Management, Negocios y blah blah blah"
    tagline "pep pepepe"
    codename "BIZ"
  end

  factory :event_type do
     name "Tipo de Evento de Prueba"
     duration 8
     elevator_pitch "un speech grooooso"
     goal "Un objetivo"
     description "Una descripción"
     recipients "algunos destinatarios"
     program "El programa del evento"
     learnings "algunas cosas"
     takeaways "un manual"
     trainers [ FactoryBot.build(:trainer) ]
   end

  factory :event do
    event_type {FactoryBot.build(:event_type)}
    date "23/01/2100"
    duration 2
    start_time "9:00"
    end_time "18:00"
    place "Hotel Conrad"
    address "Tucumán 373"
    city "Punta del Este"
    capacity 20
    visibility_type 'pu'
    list_price 500.00
    currency_iso_code "ARS"
    mode 'cl'
    cancelled false
    country FactoryBot.build(:country)
    trainer FactoryBot.build(:trainer)
  end

  factory :influence_zone do
    tag_name "ZI-AMS-AR-PAT (Patagonia)"
    zone_name "Rio Negro"
    country FactoryBot.build(:country)
  end

  factory :participant do
    id "10"
    fname "Juan Carlos"
    lname "Perez Luasó"
    email "malaimo@gmail.com"
    phone "5555-5555"
    verification_code "065BECBA36F903CF6PPP"
    event FactoryBot.build(:event)
    influence_zone FactoryBot.build(:influence_zone)
  end
  
  factory :setting do
    key "Hi"
    value "Hello"
  end
end

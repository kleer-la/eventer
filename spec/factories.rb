# encoding: utf-8
require 'factory_girl'

FactoryGirl.define do
  
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
    roles [ FactoryGirl.create(:admin_role) ]
  end

  factory :comercial, :class => User do
    email 'comercial@user.com'
    password 'please'
    password_confirmation 'please'
    roles [ FactoryGirl.create(:comercial_role) ]
  end
  
  factory :country do
    name "Argentina"
    iso_code "AR"
  end
  
  factory :trainer do
    name "Juan Alberto"
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
     trainers [ FactoryGirl.build(:trainer) ]
   end
  
  factory :event do
    event_type {FactoryGirl.build(:event_type)}
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
    is_webinar false
    country FactoryGirl.build(:country)
    trainer FactoryGirl.build(:trainer)
  end
  
  factory :influence_zone do
    tag_name "ZI-AMS-AR-PAT (Patagonia)"
    zone_name "Rio Negro"
    country FactoryGirl.build(:country)
  end
  
  factory :participant do
    fname "Juan Carlos"
    lname "Perez Luasó"
    email "juanca@perez.com"
    phone "5555-5555"
    event FactoryGirl.build(:event)
    influence_zone FactoryGirl.build(:influence_zone)
  end

end

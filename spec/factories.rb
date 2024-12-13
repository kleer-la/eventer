# frozen_string_literal: true

require 'factory_bot'

FactoryBot.define do
  factory :campaign_source do
    codename { 'source1' }
  end

  factory :campaign do
    codename { 'campaña1' }
  end

  factory :country do
    name { 'Argentina' }
    iso_code { 'AR' }
  end

  factory :event_type do
    name { 'Tipo de Evento de Prueba' }
    duration { 8 }
    elevator_pitch { 'un speech grooooso' }
    goal { 'Un objetivo' }
    description { 'Una descripción' }
    recipients { 'algunos destinatarios' }
    program { 'El programa del evento' }
    learnings { 'algunas cosas' }
    takeaways { 'un manual' }
    trainers { [FactoryBot.build(:trainer)] }
  end

  factory :event do
    event_type
    date { '23/01/2100' }
    duration { 2 }
    start_time { '9:00' }
    end_time { '18:00' }
    place { 'Hotel Conrad' }
    address { 'Tucumán 373' }
    city { 'Punta del Este' }
    capacity { 20 }
    visibility_type { 'pu' }
    list_price { 500.00 }
    currency_iso_code { 'ARS' }
    mode { 'cl' }
    cancelled { false }
    draft { false }
    country
    trainer
  end

  factory :influence_zone do
    tag_name { 'ZI-AMS-AR-PAT (Patagonia)' }
    zone_name { 'Rio Negro' }
    country
  end

  factory :participant do
    fname { 'Juan Carlos' }
    lname { 'Perez Luasó' }
    email { 'malaimo@gmail.com' }
    phone { '5555-5555' }
    verification_code { '065BECBA36F903CF6PPP' }
    event
    influence_zone
    id_number { '12345678' }
    address { 'Pago Largo 123' }
  end

  factory :setting do
    key { 'Hi' }
    value { 'Hello' }
  end

  factory :oauth_token do
    issuer { 'Xero' }
    token_set { 'Lots of encripted data' }
    tenant_id { 'global-unique-identifier' }
  end

  factory :coupon do
    coupon_type { %i[codeless percent_off amount_off].sample }
    code { Faker::Alphanumeric.alpha(number: 10).upcase }
    internal_name { 'Discount Coupon' }
    icon { 'sample_icon.png' }
    expires_on { Date.today + 30.days }
    display { true }
    active { true }
    percent_off { 20 }
    amount_off { 50 }

    trait :codeless do
      coupon_type { :codeless }
      percent_off { Faker::Number.between(from: 1, to: 100) }
    end
    trait :percent_off do
      coupon_type { :percent_off }
      percent_off { Faker::Number.between(from: 1, to: 100) }
    end

    trait :amount_off do
      coupon_type { :amount_off }
      amount_off { Faker::Number.decimal(l_digits: 2) }
    end
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :service do
    name { 'Default Service Name' }
    card_description { 'Default card description for the service.' }
    subtitle { 'Default subtitle for the service.' }
    service_area
  end
end

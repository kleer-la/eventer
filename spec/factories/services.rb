# frozen_string_literal: true

FactoryBot.define do
  factory :service do
    name { 'Default Service Name' }
    subtitle { 'Default subtitle for the service.' }
    service_area
  end
end

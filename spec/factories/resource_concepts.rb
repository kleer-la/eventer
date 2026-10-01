# frozen_string_literal: true

FactoryBot.define do
  factory :resource_concept do
    resource
    lang { 'es' }
    sequence(:position)
    sequence(:slug) { |n| "concepto-#{n}" }
    name { 'Token' }
    stage { 'Qué pasa cuando le escribís' }
    definition { 'La unidad en que el modelo lee y escribe.' }
  end
end

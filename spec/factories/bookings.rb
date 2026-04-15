# frozen_string_literal: true

FactoryBot.define do
  factory :booking do
    association :trainer
    visitor_name { 'María García' }
    visitor_email { 'maria@example.com' }
    visitor_company { 'Acme Corp' }
    starts_at { 1.day.from_now.change(hour: 10, min: 0) }
    ends_at { 1.day.from_now.change(hour: 10, min: 30) }
    status { :confirmed }
  end
end

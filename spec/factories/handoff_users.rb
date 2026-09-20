# frozen_string_literal: true

FactoryBot.define do
  factory :handoff_user do
    email { 'ana@example.com' }
    name { 'Ana' }
    google_uid { 'google-uid-1' }
    locale { 'es' }
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :resource do
    format { :card }
    slug { "resource-#{SecureRandom.hex(4)}" }
    # sequence(:slug) { |n| "resource-#{n}" }
    # slug { 'my-resource' }
    title_es { 'Mi recurso' }
    description_es { 'My resource' }
    cover_es { 'my-resource.png' }
    landing_es { '/blog/my-resource' }
  end
end

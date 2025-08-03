# frozen_string_literal: true

FactoryBot.define do
  factory :testimony do
    association :service
    first_name { 'John' }
    last_name { 'Doe' }
    profile_url { 'https://linkedin.com/in/johndoe' }
    photo_url { 'https://example.com/photos/johndoe.jpg' }
    stared { false }
    testimony { 'This service was absolutely fantastic! It exceeded all my expectations and provided tremendous value.' }

    trait :starred do
      stared { true }
    end

    trait :without_urls do
      profile_url { nil }
      photo_url { nil }
    end

    trait :with_rich_content do
      testimony { '<p>This service was <strong>absolutely fantastic</strong>! It exceeded all my expectations.</p>' }
    end
  end
end
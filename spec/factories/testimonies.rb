# frozen_string_literal: true

FactoryBot.define do
  factory :testimony do
    # Polymorphic association - defaults to Service for backward compatibility
    association :testimonial, factory: :service

    first_name { 'John' }
    last_name { 'Doe' }
    profile_url { 'https://linkedin.com/in/johndoe' }
    photo_url { 'https://example.com/photos/johndoe.jpg' }
    stared { false }
    testimony { 'This service was absolutely fantastic! It exceeded all my expectations and provided tremendous value.' }

    # Backward compatibility: set service_id for existing tests
    transient do
      service { nil }
    end

    after(:build) do |testimony, evaluator|
      if evaluator.service.present?
        testimony.service = evaluator.service
        testimony.testimonial = evaluator.service
      end
    end

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

    trait :for_event_type do
      association :testimonial, factory: :event_type
    end

    trait :for_service do
      association :testimonial, factory: :service
    end
  end
end
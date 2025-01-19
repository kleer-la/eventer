# frozen_string_literal: true

FactoryBot.define do
  factory :resource do
    format { :card }
    title_es { "Mi recurso #{SecureRandom.hex(4)}" }
    description_es { 'My resource' }
    cover_es { 'my-resource.png' }
    landing_es { '/blog/my-resource' }
    published { true }
    # association :category
  end

  factory :authorship do
    resource
    trainer
  end

  factory :illustration do
    resource
    trainer
  end

  factory :translation do
    resource
    trainer
  end
end

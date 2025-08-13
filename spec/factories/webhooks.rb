FactoryBot.define do
  factory :webhook do
    url { 'https://example.com/webhook' }
    event { 'contact.created' }
    secret { SecureRandom.hex(32) }
    active { true }
    association :responsible, factory: :trainer
    comment { 'Test webhook comment' }
  end
end

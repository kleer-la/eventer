FactoryBot.define do
  factory :webhook do
    url { 'https://example.com/webhook' }
    event { 'contact.created' }
    secret { SecureRandom.hex(32) }
    active { true }
  end
end

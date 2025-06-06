FactoryBot.define do
  factory :short_url do
    original_url { 'https://example.com' }
    short_code { SecureRandom.alphanumeric(6) }
    click_count { 0 }
  end
end
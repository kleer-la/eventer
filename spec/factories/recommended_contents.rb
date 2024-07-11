FactoryBot.define do
  factory :recommended_content do
    association :source, factory: :article
    association :target, factory: :article
    relevance_order { 1 }
  end
end

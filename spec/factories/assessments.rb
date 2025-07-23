FactoryBot.define do
  factory :assessment do
    title { 'Team Skills' }
    description { 'Evaluate team capabilities' }
    language { 'es' }
    rule_based { false }

    trait :rule_based do
      rule_based { true }
    end

    trait :english do
      language { 'en' }
    end

    trait :spanish do
      language { 'es' }
    end
  end
end

FactoryBot.define do
  factory :question do
    assessment
    text { 'Expertise Level' }
    position { 1 }
    question_type { 'linear_scale' }

    trait :with_group do
      question_group
    end
  end
end

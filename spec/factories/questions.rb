FactoryBot.define do
  factory :question do
    assessment
    name { 'Expertise Level' }
    position { 1 }
    question_type { 'linear_scale' }

    trait :with_group do
      question_group
    end

    trait :radio_button do
      question_type { 'radio_button' }
      name { 'Choose your experience level' }
    end

    trait :short_text do
      question_type { 'short_text' }
      name { 'Enter your name' }
    end

    trait :long_text do
      question_type { 'long_text' }
      name { 'Describe your experience' }
    end
  end
end

FactoryBot.define do
  factory :response do
    association :contact
    association :question
    answer { nil }

    trait :with_answer do
      association :answer
      text_response { nil }
    end

    trait :with_text do
      answer { nil }
      text_response { "Sample text response" }
    end

    trait :linear_scale do
      with_answer
      after(:build) do |response|
        response.question.update(question_type: 'linear_scale')
      end
    end

    trait :radio_button do
      with_answer
      after(:build) do |response|
        response.question.update(question_type: 'radio_button')
      end
    end

    trait :short_text do
      with_text
      after(:build) do |response|
        response.question.update(question_type: 'short_text')
      end
    end

    trait :long_text do
      with_text
      text_response { "This is a longer text response with more detail about the question." }
      after(:build) do |response|
        response.question.update(question_type: 'long_text')
      end
    end
  end
end
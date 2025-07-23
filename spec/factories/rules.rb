FactoryBot.define do
  factory :rule do
    association :assessment
    position { 1 }
    conditions { '{}' }
    diagnostic_text { "Sample diagnostic text" }

    trait :with_exact_value_condition do
      transient do
        question_id { nil }
        expected_value { 1 }
      end

      conditions do
        { question_id => { "value" => expected_value } }.to_json
      end
    end

    trait :with_range_condition do
      transient do
        question_id { nil }
        min_value { 1 }
        max_value { 3 }
      end

      conditions do
        { question_id => { "range" => [min_value, max_value] } }.to_json
      end
    end

    trait :with_text_contains_condition do
      transient do
        question_id { nil }
        search_text { "keyword" }
      end

      conditions do
        { question_id => { "text_contains" => search_text } }.to_json
      end
    end

    trait :with_any_value_condition do
      transient do
        question_id { nil }
      end

      conditions do
        { question_id => nil }.to_json
      end
    end

    trait :with_multiple_conditions do
      transient do
        question1_id { nil }
        question2_id { nil }
        value1 { 2 }
        range_min { 1 }
        range_max { 3 }
      end

      conditions do
        {
          question1_id => { "value" => value1 },
          question2_id => { "range" => [range_min, range_max] }
        }.to_json
      end
    end
  end
end
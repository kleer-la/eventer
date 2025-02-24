FactoryBot.define do
  factory :question_group do
    assessment
    name { 'Domain' }
    position { 1 }
  end
end

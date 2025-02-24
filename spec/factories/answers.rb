FactoryBot.define do
  factory :answer do
    question
    text { 'Low' }
    position { 1 }
  end
end
